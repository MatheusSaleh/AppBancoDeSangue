import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../repositories/repositories.dart';

/// Failure reported by the API, with the HTTP status (null when the server
/// could not be reached).
class ApiException extends AppException {
  const ApiException(super.message, {this.statusCode});

  final int? statusCode;
}

/// Thin JSON client for `apps/api`. Converts every failure into an
/// [AppException] with a message that can be shown to the user, and reports
/// 401 responses so the session can be cleared.
class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
  }) : _base = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'),
       _http = httpClient ?? http.Client();

  final Uri _base;
  final http.Client _http;
  final Duration timeout;

  /// Bearer token of the current session, if any.
  String? token;

  /// Called when an authenticated request gets 401 (expired or revoked).
  void Function()? onUnauthorized;

  Future<Object?> get(String path) => _send('GET', path);
  Future<Object?> post(String path, [Object? body, Duration? requestTimeout]) =>
      _send('POST', path, body, requestTimeout);
  Future<Object?> put(String path, Object? body) => _send('PUT', path, body);
  Future<Object?> delete(String path) => _send('DELETE', path);

  Future<Object?> _send(
    String method,
    String path, [
    Object? body,
    Duration? requestTimeout,
  ]) async {
    final request = http.Request(method, _base.resolve(path))
      ..headers['Accept'] = 'application/json';
    final authToken = token;
    if (authToken != null) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await _http
          .send(request)
          .then(http.Response.fromStream)
          .timeout(requestTimeout ?? timeout);
    } on TimeoutException {
      throw const ApiException(
        'O servidor demorou para responder. Tente novamente.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    }

    final decoded = response.body.isEmpty ? null : _tryDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;

    if (response.statusCode == 401 && authToken != null) onUnauthorized?.call();
    throw ApiException(
      _errorMessage(decoded, response.statusCode),
      statusCode: response.statusCode,
    );
  }

  static Object? _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  static String _errorMessage(Object? body, int status) {
    if (body case {'error': {'message': final String message}}) return message;
    return switch (status) {
      401 => 'Sessão expirada. Entre novamente.',
      403 => 'Você não tem permissão para esta ação.',
      404 => 'Registro não encontrado.',
      429 => 'Muitas tentativas. Aguarde um minuto.',
      >= 500 => 'Erro no servidor. Tente novamente mais tarde.',
      _ => 'Não foi possível concluir a operação.',
    };
  }
}

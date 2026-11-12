import 'dart:convert';

import 'package:appbancodesangue/data/api/api_ai_repository.dart';
import 'package:appbancodesangue/data/api/api_client.dart';
import 'package:appbancodesangue/data/repositories/repositories.dart';
import 'package:appbancodesangue/domain/models/ai_chat.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('daily quota errors reach both AI screens without signing the user out', () async {
    const message =
        'Seu limite diário de 20 solicitações de IA foi atingido. A cota renova à meia-noite.';
    final client = ApiClient(
      baseUrl: 'http://app.test',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'error': {'code': 'ai_daily_limit_exceeded', 'message': message},
          }),
          429,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    )..token = 'session-token';
    var signedOut = false;
    client.onUnauthorized = () => signedOut = true;
    final ai = ApiAiRepository(client);
    for (final request in [
      ai.generateQuiz(),
      ai.chat([const ChatMessage(role: 'user', content: 'Como doar?')]),
    ]) {
      await expectLater(
        request,
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 429)
              .having((e) => e.message, 'message', message),
        ),
      );
    }
    expect(signedOut, isFalse);
    expect(client.token, 'session-token');
  });

  test(
    'AI requests use only app bearer tokens and conversation messages',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        baseUrl: 'http://app.test',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({
              'reply': 'Resposta',
              'suggestions': ['Pergunta 1', 'Pergunta 2'],
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      )..token = 'session-token';
      final result = await ApiAiRepository(client)
          .chat([const ChatMessage(role: 'user', content: 'Como doar?')]);
      expect(result.reply, 'Resposta');
      expect(requests.single.url.path, '/ai/chat');
      expect(requests.single.headers['Authorization'], 'Bearer session-token');
      expect(jsonDecode(requests.single.body), {
        'messages': [
          {'role': 'user', 'content': 'Como doar?'},
        ],
      });
    },
  );

  test('malformed quizzes become recoverable app errors', () async {
    final client = ApiClient(
      baseUrl: 'http://app.test',
      httpClient: MockClient(
        (_) async => http.Response('{"questions": []}', 200),
      ),
    );
    await expectLater(
      ApiAiRepository(client).generateQuiz(),
      throwsA(isA<AppException>()),
    );
  });

  test('missing Venice configuration shows the server message', () async {
    final client = ApiClient(
      baseUrl: 'http://app.test',
      httpClient: MockClient(
        (_) async => http.Response(
          '{"error":{"message":"Configure VENICE_API_KEY"}}',
          503,
        ),
      ),
    );
    await expectLater(
      ApiAiRepository(client).generateQuiz(),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          'Configure VENICE_API_KEY',
        ),
      ),
    );
  });
}

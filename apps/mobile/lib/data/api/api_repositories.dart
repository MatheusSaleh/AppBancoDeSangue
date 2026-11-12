import 'dart:async';

import '../../domain/models/blood_type.dart';
import '../../domain/models/donation.dart';
import '../../domain/models/donor_profile.dart';
import '../../domain/models/news_article.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';
import 'token_store.dart';

typedef Json = Map<String, Object?>;

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client, this._tokens) {
    // A 401 on any request means the session ended on the server.
    _client.onUnauthorized = () => unawaited(_endSession());
  }

  final ApiClient _client;
  final TokenStore _tokens;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  /// Restores the stored session by validating the token with `/auth/me`.
  /// A rejected token (401) is discarded. If the server is unreachable the
  /// token is kept for the next launch, but the user starts signed out
  /// because their data could not be loaded anyway.
  Future<void> restore() async {
    final token = await _tokens.read();
    if (token == null) return;
    _client.token = token;
    try {
      final me = await _client.get('auth/me') as Json;
      _user = _userFrom(me);
    } on ApiException catch (e) {
      _client.token = null;
      if (e.statusCode == 401) await _tokens.clear();
    }
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() {
    StreamSubscription<AppUser?>? inner;
    late final StreamController<AppUser?> controller;
    controller = StreamController<AppUser?>(
      onListen: () {
        controller.add(_user);
        inner = _controller.stream.listen(controller.add);
      },
      onCancel: () => inner?.cancel(),
    );
    return controller.stream;
  }

  @override
  bool get supportsEmailPassword => true;

  @override
  bool get supportsGuest => false;

  @override
  Future<void> signIn({required String email, required String password}) =>
      _startSession('auth/login', email, password);

  @override
  Future<void> signUp({required String email, required String password}) =>
      _startSession('auth/register', email, password);

  @override
  Future<void> sendPasswordReset(String email) =>
      _client.post('auth/password-reset/request', {'email': email.trim()});

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) => _client.post('auth/password-reset/confirm', {
    'token': code.trim(),
    'password': newPassword,
  });

  @override
  Future<void> signInAsGuest() => Future.error(
    const AppException('O modo visitante só existe na demonstração.'),
  );

  @override
  Future<void> signOut() async {
    try {
      await _client.post('auth/logout');
    } on AppException {
      // Signing out locally must work even if the server is unreachable.
    }
    await _endSession();
  }

  Future<void> _startSession(String path, String email, String password) async {
    final body = await _client.post(path, {
      'email': email.trim(),
      'password': password,
    }) as Json;
    final token = body['token']! as String;
    _client.token = token;
    await _tokens.write(token);
    _emit(_userFrom(body['user']! as Json));
  }

  Future<void> _endSession() async {
    _client.token = null;
    await _tokens.clear();
    if (_user != null) _emit(null);
  }

  void _emit(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  static AppUser _userFrom(Json json) =>
      AppUser(id: json['id']! as String, email: json['email'] as String?);
}

/// Donation dates travel as `YYYY-MM-DD`: the rules work with calendar days,
/// so no time zone conversion is involved.
class ApiDonationRepository implements DonationRepository {
  ApiDonationRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Donation>> fetchAll(String userId) async {
    final list = await _client.get('donations') as List<Object?>;
    return list.cast<Json>().map(_fromJson).toList();
  }

  @override
  Future<Donation> add(String userId, Donation donation) async =>
      _fromJson(await _client.post('donations', _toJson(donation)) as Json);

  @override
  Future<void> update(String userId, Donation donation) =>
      _client.put('donations/${donation.id}', _toJson(donation));

  @override
  Future<void> delete(String userId, String donationId) =>
      _client.delete('donations/$donationId');

  static Json _toJson(Donation d) => {
    'date': formatIsoDate(d.date),
    'location': d.location,
    'notes': d.notes,
  };

  static Donation _fromJson(Json json) => Donation(
    id: json['id']! as String,
    date: DateTime.parse(json['date']! as String),
    location: json['location'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
  );
}

String formatIsoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._client);

  final ApiClient _client;

  @override
  Future<DonorProfile> fetch(String userId) async {
    final json = await _client.get('profile') as Json;
    return DonorProfile(
      name: json['name'] as String? ?? '',
      sex: BiologicalSex.fromStorage(json['sex'] as String?),
      bloodType: BloodType.fromLabel(json['bloodType'] as String?),
    );
  }

  @override
  Future<void> save(String userId, DonorProfile profile) =>
      _client.put('profile', {
        'name': profile.name,
        'sex': profile.sex?.storageValue,
        'bloodType': profile.bloodType?.label,
      });
}

class ApiNewsRepository implements NewsRepository {
  ApiNewsRepository(this._client);

  final ApiClient _client;

  @override
  bool get isDemoContent => false;

  @override
  Future<List<NewsArticle>> fetchAll() async {
    final list = await _client.get('news') as List<Object?>;
    return list
        .cast<Json>()
        .map(
          (n) => NewsArticle(
            id: n['id']! as String,
            title: n['title']! as String,
            summary: n['summary'] as String? ?? '',
            body: n['body'] as String? ?? '',
            publishedAt: DateTime.tryParse(n['publishedAt'] as String? ?? ''),
          ),
        )
        .toList();
  }
}

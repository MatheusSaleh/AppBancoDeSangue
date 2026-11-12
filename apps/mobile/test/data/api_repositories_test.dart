import 'dart:convert';

import 'package:appbancodesangue/data/api/api_client.dart';
import 'package:appbancodesangue/data/api/api_repositories.dart';
import 'package:appbancodesangue/data/api/token_store.dart';
import 'package:appbancodesangue/data/repositories/repositories.dart';
import 'package:appbancodesangue/domain/models/blood_type.dart';
import 'package:appbancodesangue/domain/models/donation.dart';
import 'package:appbancodesangue/domain/models/donor_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Records requests and answers from a route table.
class FakeApi {
  final requests = <http.Request>[];
  final routes = <String, http.Response Function(http.Request)>{};

  late final client = MockClient((request) async {
    requests.add(request);
    final handler = routes['${request.method} ${request.url.path}'];
    if (handler == null) {
      return _json({
        'error': {'message': 'Rota não encontrada.'},
      }, 404);
    }
    return handler(request);
  });

  /// Registers a handler; chainable without cascade/closure ambiguity.
  FakeApi on(String route, http.Response Function(http.Request) handler) {
    routes[route] = handler;
    return this;
  }

  ApiClient api() => ApiClient(baseUrl: 'http://api.test', httpClient: client);
}

http.Response _json(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _session = {
  'token': 'tok_abcdefghijklmnopqrstuvwxyz',
  'expiresAt': '2026-12-11T00:00:00.000Z',
  'user': {'id': 'u1', 'email': 'ana@example.com', 'role': 'user'},
};

void main() {
  group('ApiAuthRepository', () {
    test('login stores the token and authenticates later requests', () async {
      final fake = FakeApi()
          .on('POST /auth/login', (_) => _json(_session))
          .on('GET /donations', (_) => _json([]));
      final client = fake.api();
      final tokens = InMemoryTokenStore();
      final auth = ApiAuthRepository(client, tokens);

      await auth.signIn(email: ' ana@example.com ', password: 'senha-123');

      expect(auth.currentUser?.id, 'u1');
      expect(tokens.token, _session['token']);
      expect(jsonDecode(fake.requests.first.body), {
        'email': 'ana@example.com',
        'password': 'senha-123',
      });

      await ApiDonationRepository(client).fetchAll('u1');
      expect(
        fake.requests.last.headers['Authorization'],
        'Bearer ${_session['token']}',
      );
    });

    test('shows the server message on failure', () async {
      final fake = FakeApi().on(
        'POST /auth/login',
        (_) => _json({
          'error': {
            'code': 'invalid_credentials',
            'message': 'E-mail ou senha incorretos.',
          },
        }, 401),
      );
      final auth = ApiAuthRepository(fake.api(), InMemoryTokenStore());
      expect(
        auth.signIn(email: 'a@b.com', password: 'x'),
        throwsA(
          isA<AppException>().having(
            (e) => e.message,
            'message',
            'E-mail ou senha incorretos.',
          ),
        ),
      );
    });

    test('restore validates the stored token', () async {
      final fake = FakeApi().on('GET /auth/me', (_) => _json(_session['user']));
      final auth = ApiAuthRepository(fake.api(), InMemoryTokenStore('tok'));
      await auth.restore();
      expect(auth.currentUser?.email, 'ana@example.com');
    });

    test('restore discards a rejected token', () async {
      final fake = FakeApi().on('GET /auth/me', (_) => _json({}, 401));
      final tokens = InMemoryTokenStore('tok');
      final auth = ApiAuthRepository(fake.api(), tokens);
      await auth.restore();
      expect(auth.currentUser, isNull);
      expect(tokens.token, isNull);
    });

    test('restore keeps the token when the server is unreachable', () async {
      final offline = MockClient((_) => throw http.ClientException('offline'));
      final tokens = InMemoryTokenStore('tok');
      final auth = ApiAuthRepository(
        ApiClient(baseUrl: 'http://api.test', httpClient: offline),
        tokens,
      );
      await auth.restore();
      expect(auth.currentUser, isNull);
      expect(tokens.token, 'tok');
    });

    test('a 401 on any request ends the session', () async {
      final fake = FakeApi()
          .on('POST /auth/login', (_) => _json(_session))
          .on(
            'GET /donations',
            (_) => _json({
              'error': {'message': 'Sessão inválida.'},
            }, 401),
          );
      final client = fake.api();
      final tokens = InMemoryTokenStore();
      final auth = ApiAuthRepository(client, tokens);
      final events = <AppUser?>[];
      auth.authStateChanges().listen(events.add);

      await auth.signIn(email: 'ana@example.com', password: 'senha-123');
      await expectLater(
        ApiDonationRepository(client).fetchAll('u1'),
        throwsA(isA<AppException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(auth.currentUser, isNull);
      expect(tokens.token, isNull);
      expect(events.map((u) => u?.id), [null, 'u1', null]);
    });

    test('sign out works even when the server is unreachable', () async {
      final fake = FakeApi().on('POST /auth/login', (_) => _json(_session));
      final tokens = InMemoryTokenStore();
      final auth = ApiAuthRepository(fake.api(), tokens);
      await auth.signIn(email: 'ana@example.com', password: 'senha-123');
      fake.routes.remove('POST /auth/login');
      // /auth/logout is not routed: the fake answers 404.
      await auth.signOut();
      expect(auth.currentUser, isNull);
      expect(tokens.token, isNull);
    });

    test('password reset sends code and new password', () async {
      final fake = FakeApi().on(
        'POST /auth/password-reset/confirm',
        (_) => http.Response('', 204),
      );
      final auth = ApiAuthRepository(fake.api(), InMemoryTokenStore());
      await auth.confirmPasswordReset(
        code: ' codigo ',
        newPassword: 'nova-123',
      );
      expect(jsonDecode(fake.requests.single.body), {
        'token': 'codigo',
        'password': 'nova-123',
      });
    });
  });

  test('donations travel as calendar dates (YYYY-MM-DD)', () async {
    final fake = FakeApi()
        .on(
          'POST /donations',
          (r) => _json({
            'id': 'd1',
            ...(jsonDecode(r.body) as Map<String, Object?>),
          }, 201),
        )
        .on(
          'GET /donations',
          (_) => _json([
            {'id': 'd1', 'date': '2026-03-05', 'location': 'HC', 'notes': ''},
          ]),
        );
    final repo = ApiDonationRepository(fake.api());

    final saved = await repo.add(
      'u1',
      Donation(id: '', date: DateTime(2026, 3, 5, 23, 59), location: 'HC'),
    );
    expect(
      (jsonDecode(fake.requests.first.body) as Map<String, Object?>)['date'],
      '2026-03-05',
    );
    expect(saved.id, 'd1');

    final list = await repo.fetchAll('u1');
    expect(list.single.date, DateTime(2026, 3, 5));
  });

  test('profile maps sex and blood type', () async {
    final fake = FakeApi()
        .on(
          'GET /profile',
          (_) => _json({'name': 'Ana', 'sex': 'feminino', 'bloodType': 'AB-'}),
        )
        .on('PUT /profile', (r) => _json(jsonDecode(r.body) as Object?));
    final repo = ApiProfileRepository(fake.api());

    final profile = await repo.fetch('u1');
    expect(profile.sex, BiologicalSex.female);
    expect(profile.bloodType, BloodType.abNegative);

    await repo.save('u1', const DonorProfile(name: 'Ana'));
    expect(jsonDecode(fake.requests.last.body), {
      'name': 'Ana',
      'sex': null,
      'bloodType': null,
    });
  });

  test('network failures become friendly messages', () async {
    final offline = MockClient((_) => throw http.ClientException('offline'));
    final repo = ApiNewsRepository(
      ApiClient(baseUrl: 'http://api.test', httpClient: offline),
    );
    expect(
      repo.fetchAll(),
      throwsA(
        isA<AppException>().having(
          (e) => e.message,
          'message',
          contains('Não foi possível conectar'),
        ),
      ),
    );
  });
}

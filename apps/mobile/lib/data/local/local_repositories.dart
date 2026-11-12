import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../../domain/models/donation.dart';
import '../../domain/models/donor_profile.dart';
import '../../domain/models/news_article.dart';
import '../repositories/repositories.dart';
import 'key_value_store.dart';

/// Demo-mode authentication: a single local guest session, no passwords
/// stored on the device.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._store);

  static const _sessionKey = 'demo.session';
  static const guestId = 'visitante-local';

  final KeyValueStore _store;
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  /// Restores a previous guest session, if any.
  Future<void> restore() async {
    if (await _store.getString(_sessionKey) == guestId) {
      _user = const AppUser(id: guestId, isGuest: true);
    }
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() {
    // Subscribes synchronously on listen, so no event emitted between the
    // initial value and the subscription can be lost (an `async*` generator
    // would only subscribe after its first yield is delivered).
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
  bool get supportsEmailPassword => false;

  @override
  bool get supportsGuest => true;

  @override
  Future<void> signInAsGuest() async {
    await _store.setString(_sessionKey, guestId);
    _emit(const AppUser(id: guestId, isGuest: true));
  }

  @override
  Future<void> signOut() async {
    await _store.remove(_sessionKey);
    _emit(null);
  }

  void _emit(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  static const _unsupported = AppException(
    'Contas com e-mail e senha exigem a API (BACKEND=api). '
    'No modo demonstração, entre como visitante.',
  );

  @override
  Future<void> signIn({required String email, required String password}) =>
      Future.error(_unsupported);

  @override
  Future<void> signUp({required String email, required String password}) =>
      Future.error(_unsupported);

  @override
  Future<void> sendPasswordReset(String email) => Future.error(_unsupported);

  @override
  Future<void> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) => Future.error(_unsupported);
}

class LocalDonationRepository implements DonationRepository {
  LocalDonationRepository(this._store, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final KeyValueStore _store;
  final DateTime Function() _clock;
  final _random = Random();
  int _sequence = 0;

  String _key(String userId) => 'donations.$userId';

  /// Timestamps alone collide when records are created in quick succession
  /// (clock resolution is coarse on Windows and on the web), so a sequence
  /// number and a random suffix are added.
  String _newId() =>
      'local-${_clock().microsecondsSinceEpoch}-${_sequence++}-'
      '${_random.nextInt(1 << 32).toRadixString(36)}';

  Future<List<Donation>> _read(String userId) async {
    final raw = await _store.getString(_key(userId));
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .cast<Map<String, dynamic>>()
          .map(_fromJson)
          .whereType<Donation>()
          .toList();
    } on FormatException {
      throw const AppException('Os dados locais estão corrompidos.');
    }
  }

  Future<void> _write(String userId, List<Donation> donations) => _store
      .setString(_key(userId), jsonEncode(donations.map(_toJson).toList()));

  @override
  Future<List<Donation>> fetchAll(String userId) async {
    final list = await _read(userId);
    return list..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<Donation> add(String userId, Donation donation) async {
    final list = await _read(userId);
    final saved = donation.copyWith(id: _newId());
    await _write(userId, [...list, saved]);
    return saved;
  }

  @override
  Future<void> update(String userId, Donation donation) async {
    final list = await _read(userId);
    final index = list.indexWhere((d) => d.id == donation.id);
    if (index < 0) throw const AppException('Doação não encontrada.');
    list[index] = donation;
    await _write(userId, list);
  }

  @override
  Future<void> delete(String userId, String donationId) async {
    final list = await _read(userId);
    await _write(userId, list.where((d) => d.id != donationId).toList());
  }

  static Map<String, Object?> _toJson(Donation d) => {
    'id': d.id,
    'data': d.date.toIso8601String(),
    'local': d.location,
    'observacoes': d.notes,
  };

  static Donation? _fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['data'] as String? ?? '');
    final id = json['id'] as String?;
    if (date == null || id == null) return null;
    return Donation(
      id: id,
      date: date,
      location: json['local'] as String? ?? '',
      notes: json['observacoes'] as String? ?? '',
    );
  }
}

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository(this._store);

  final KeyValueStore _store;

  String _key(String userId) => 'profile.$userId';

  @override
  Future<DonorProfile> fetch(String userId) async {
    final raw = await _store.getString(_key(userId));
    if (raw == null) return DonorProfile.empty;
    return DonorProfile.fromJson(jsonDecode(raw) as Map<String, Object?>);
  }

  @override
  Future<void> save(String userId, DonorProfile profile) =>
      _store.setString(_key(userId), jsonEncode(profile.toJson()));
}

/// Sample articles shown in demo mode. They are explicitly flagged as demo
/// content in the UI and are not real news.
class DemoNewsRepository implements NewsRepository {
  const DemoNewsRepository();

  @override
  bool get isDemoContent => true;

  @override
  Future<List<NewsArticle>> fetchAll() async => const [
    NewsArticle(
      id: 'demo-1',
      title: 'Exemplo: campanha de inverno',
      summary:
          'Artigo fictício que mostra como os comunicados do '
          'hemocentro aparecem no app.',
      body:
          'Com a API, as notícias são publicadas por administradores '
          '(POST /news) e lidas por todos os usuários.',
    ),
    NewsArticle(
      id: 'demo-2',
      title: 'Exemplo: estoque de O- em alerta',
      summary:
          'Artigo fictício. Comunicados reais podem avisar quando '
          'um tipo sanguíneo está com estoque baixo.',
    ),
    NewsArticle(
      id: 'demo-3',
      title: 'Exemplo: horário especial de coleta',
      summary:
          'Artigo fictício sobre mudanças de horário de '
          'atendimento.',
    ),
  ];
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/repositories.dart';
import '../../domain/models/donation.dart';
import '../../domain/models/donor_profile.dart';
import '../../domain/rules/donation_eligibility.dart';

enum LoadState { idle, loading, ready, error }

/// State of the signed-in donor: profile, donation history and the derived
/// eligibility. Shared by home, history, form and profile screens.
class DonorViewModel extends ChangeNotifier {
  DonorViewModel({
    required this._auth,
    required this._donations,
    required this._profiles,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _sub = _auth.authStateChanges().listen(_onUserChanged);
  }

  final AuthRepository _auth;
  final DonationRepository _donations;
  final ProfileRepository _profiles;
  final DateTime Function() _clock;
  late final StreamSubscription<AppUser?> _sub;

  String? _userId;
  LoadState _state = LoadState.idle;
  String? _error;
  List<Donation> _history = const [];
  DonorProfile _profile = DonorProfile.empty;

  LoadState get state => _state;
  String? get error => _error;
  List<Donation> get history => _history;
  DonorProfile get profile => _profile;
  DateTime get today => _clock();

  EligibilityResult get eligibility => evaluateEligibility(
    donations: _history,
    sex: _profile.sex,
    today: _clock(),
  );

  Donation? findById(String id) {
    for (final d in _history) {
      if (d.id == id) return d;
    }
    return null;
  }

  void _onUserChanged(AppUser? user) {
    if (user?.id == _userId) return;
    _userId = user?.id;
    _history = const [];
    _profile = DonorProfile.empty;
    if (user == null) {
      _state = LoadState.idle;
      notifyListeners();
    } else {
      load();
    }
  }

  Future<void> load() async {
    final userId = _userId;
    if (userId == null) return;
    _state = LoadState.loading;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _profiles.fetch(userId),
        _donations.fetchAll(userId),
      ]);
      if (userId != _userId) return; // user changed meanwhile
      _profile = results[0] as DonorProfile;
      _history = results[1] as List<Donation>;
      _state = LoadState.ready;
    } on AppException catch (e) {
      _error = e.message;
      _state = LoadState.error;
    } catch (_) {
      _error = 'Não foi possível carregar seus dados.';
      _state = LoadState.error;
    }
    notifyListeners();
  }

  DonationDateIssue? validateDate(DateTime date, {String? editingId}) =>
      validateDonationDate(
        date: date,
        today: _clock(),
        existing: _history,
        sex: _profile.sex,
        editingId: editingId,
      );

  Future<void> saveDonation(Donation donation) async {
    final userId = _requireUser();
    if (donation.id.isEmpty) {
      await _donations.add(userId, donation);
    } else {
      await _donations.update(userId, donation);
    }
    await _refreshHistory(userId);
  }

  Future<void> deleteDonation(String id) async {
    final userId = _requireUser();
    await _donations.delete(userId, id);
    await _refreshHistory(userId);
  }

  /// Re-inserts a donation removed by mistake (used by the "Desfazer" action).
  Future<void> restoreDonation(Donation donation) =>
      saveDonation(donation.copyWith(id: ''));

  /// Demo helper: adds clearly labelled sample records so evaluators can see
  /// the history and the eligibility countdown without typing data.
  Future<void> addSampleDonations() async {
    final userId = _requireUser();
    final now = _clock();
    for (final daysAgo in [200, 110, 40]) {
      await _donations.add(
        userId,
        Donation(
          id: '',
          date: DateTime(now.year, now.month, now.day - daysAgo),
          location: 'Hemocentro (exemplo)',
          notes: 'Registro de exemplo do modo demonstração.',
        ),
      );
    }
    await _refreshHistory(userId);
  }

  Future<void> saveProfile(DonorProfile profile) async {
    final userId = _requireUser();
    await _profiles.save(userId, profile);
    _profile = profile;
    notifyListeners();
  }

  Future<void> _refreshHistory(String userId) async {
    _history = await _donations.fetchAll(userId);
    notifyListeners();
  }

  String _requireUser() {
    final id = _userId;
    if (id == null) {
      throw const AppException('Sessão expirada. Entre novamente.');
    }
    return id;
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

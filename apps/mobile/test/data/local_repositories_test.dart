import 'package:appbancodesangue/data/local/key_value_store.dart';
import 'package:appbancodesangue/data/local/local_repositories.dart';
import 'package:appbancodesangue/data/repositories/repositories.dart';
import 'package:appbancodesangue/domain/models/blood_type.dart';
import 'package:appbancodesangue/domain/models/donation.dart';
import 'package:appbancodesangue/domain/models/donor_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalDonationRepository', () {
    late InMemoryStore store;
    late LocalDonationRepository repo;
    var tick = 0;

    setUp(() {
      store = InMemoryStore();
      repo = LocalDonationRepository(
        store,
        clock: () => DateTime(2026).add(Duration(microseconds: tick++)),
      );
    });

    test('adds, lists (most recent first), updates and deletes', () async {
      final a = await repo.add(
        'u1',
        Donation(id: '', date: DateTime(2026, 1, 1)),
      );
      final b = await repo.add(
        'u1',
        Donation(id: '', date: DateTime(2026, 6, 1), location: 'Hemocentro'),
      );
      expect(a.id, isNot(b.id));

      var all = await repo.fetchAll('u1');
      expect(all.map((d) => d.id), [b.id, a.id]);

      await repo.update('u1', a.copyWith(notes: 'ok'));
      all = await repo.fetchAll('u1');
      expect(all.last.notes, 'ok');

      await repo.delete('u1', b.id);
      expect((await repo.fetchAll('u1')).single.id, a.id);
    });

    test('isolates data per user and survives a new instance', () async {
      await repo.add('u1', Donation(id: '', date: DateTime(2026, 1, 1)));
      final reopened = LocalDonationRepository(store);
      expect(await reopened.fetchAll('u1'), hasLength(1));
      expect(await reopened.fetchAll('u2'), isEmpty);
    });

    test('updating a missing record throws AppException', () {
      expect(
        repo.update('u1', Donation(id: 'nope', date: DateTime(2026))),
        throwsA(isA<AppException>()),
      );
    });

    test('corrupted storage surfaces a friendly error', () {
      store.values['donations.u1'] = '{not json';
      expect(repo.fetchAll('u1'), throwsA(isA<AppException>()));
    });
  });

  test('LocalProfileRepository round-trips the profile', () async {
    final repo = LocalProfileRepository(InMemoryStore());
    expect(await repo.fetch('u1'), DonorProfile.empty);
    const profile = DonorProfile(
      name: 'Ana',
      sex: BiologicalSex.female,
      bloodType: BloodType.oNegative,
    );
    await repo.save('u1', profile);
    expect(await repo.fetch('u1'), profile);
  });

  group('LocalAuthRepository', () {
    test('guest session persists and can be restored', () async {
      final store = InMemoryStore();
      final auth = LocalAuthRepository(store);
      await auth.restore();
      expect(auth.currentUser, isNull);

      await auth.signInAsGuest();
      expect(auth.currentUser?.isGuest, isTrue);

      final restored = LocalAuthRepository(store);
      await restored.restore();
      expect(restored.currentUser?.id, LocalAuthRepository.guestId);

      await restored.signOut();
      final afterSignOut = LocalAuthRepository(store);
      await afterSignOut.restore();
      expect(afterSignOut.currentUser, isNull);
    });

    test('emits the current state first, then changes', () async {
      final auth = LocalAuthRepository(InMemoryStore());
      final events = <AppUser?>[];
      final sub = auth.authStateChanges().listen(events.add);
      await Future<void>.delayed(Duration.zero);
      await auth.signInAsGuest();
      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(events.map((u) => u?.id), [
        null,
        LocalAuthRepository.guestId,
        null,
      ]);
    });

    test('e-mail/password is not available in demo mode', () {
      final auth = LocalAuthRepository(InMemoryStore());
      expect(auth.supportsEmailPassword, isFalse);
      expect(
        auth.signIn(email: 'a@b.com', password: '12345678'),
        throwsA(isA<AppException>()),
      );
    });
  });

  test('demo news is flagged as demo content', () async {
    const repo = DemoNewsRepository();
    expect(repo.isDemoContent, isTrue);
    expect(await repo.fetchAll(), isNotEmpty);
  });
}

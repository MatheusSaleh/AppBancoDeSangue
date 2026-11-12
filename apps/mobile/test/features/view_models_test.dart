import 'package:appbancodesangue/data/local/key_value_store.dart';
import 'package:appbancodesangue/data/local/local_repositories.dart';
import 'package:appbancodesangue/data/repositories/repositories.dart';
import 'package:appbancodesangue/domain/models/donation.dart';
import 'package:appbancodesangue/domain/models/donor_profile.dart';
import 'package:appbancodesangue/domain/rules/donation_eligibility.dart';
import 'package:appbancodesangue/features/auth/validators.dart';
import 'package:appbancodesangue/features/donations/donor_view_model.dart';
import 'package:appbancodesangue/features/quiz/quiz_questions.dart';
import 'package:appbancodesangue/features/quiz/quiz_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingDonations implements DonationRepository {
  @override
  Future<List<Donation>> fetchAll(String userId) =>
      Future.error(const AppException('Sem conexão.'));
  @override
  Future<Donation> add(String userId, Donation donation) =>
      throw UnimplementedError();
  @override
  Future<void> update(String userId, Donation donation) =>
      throw UnimplementedError();
  @override
  Future<void> delete(String userId, String donationId) =>
      throw UnimplementedError();
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  final today = DateTime(2026, 11, 11);

  group('DonorViewModel', () {
    late LocalAuthRepository auth;
    late DonorViewModel vm;

    setUp(() async {
      final store = InMemoryStore();
      auth = LocalAuthRepository(store);
      vm = DonorViewModel(
        auth: auth,
        donations: LocalDonationRepository(store),
        profiles: LocalProfileRepository(store),
        clock: () => today,
      );
      await _settle();
    });

    tearDown(() => vm.dispose());

    test('loads when a user signs in and resets on sign out', () async {
      expect(vm.state, LoadState.idle);
      await auth.signInAsGuest();
      await _settle();
      expect(vm.state, LoadState.ready);

      await vm.saveProfile(
        const DonorProfile(name: 'Ana', sex: BiologicalSex.male),
      );
      await vm.saveDonation(Donation(id: '', date: DateTime(2026, 10, 1)));
      expect(vm.history, hasLength(1));
      expect(vm.eligibility.status, EligibilityStatus.waitingInterval);

      await auth.signOut();
      await _settle();
      expect(vm.history, isEmpty);
      expect(vm.profile, DonorProfile.empty);
      expect(vm.state, LoadState.idle);
    });

    test('delete and undo keep the history consistent', () async {
      await auth.signInAsGuest();
      await _settle();
      await vm.saveDonation(Donation(id: '', date: DateTime(2026, 1, 1)));
      final saved = vm.history.single;
      await vm.deleteDonation(saved.id);
      expect(vm.history, isEmpty);
      await vm.restoreDonation(saved);
      expect(vm.history.single.date, saved.date);
    });

    test('sample donations are labelled and in the past', () async {
      await auth.signInAsGuest();
      await _settle();
      await vm.addSampleDonations();
      expect(vm.history, hasLength(3));
      expect(vm.history.every((d) => d.date.isBefore(today)), isTrue);
      expect(vm.history.every((d) => d.notes.contains('exemplo')), isTrue);
    });

    test('exposes repository errors as an error state', () async {
      final failing = DonorViewModel(
        auth: auth,
        donations: _FailingDonations(),
        profiles: LocalProfileRepository(InMemoryStore()),
      );
      await _settle();
      await auth.signInAsGuest();
      await _settle();
      await _settle();
      expect(failing.state, LoadState.error);
      expect(failing.error, 'Sem conexão.');
      failing.dispose();
    });
  });

  group('QuizViewModel', () {
    test('counts correct answers and ignores double taps', () {
      final quiz = QuizViewModel(quizQuestions);
      for (final q in quizQuestions) {
        quiz.answer(q.correctIndex);
        quiz.answer((q.correctIndex + 1) % q.options.length); // ignored
        expect(quiz.lastAnswerCorrect, isTrue);
        quiz.next();
      }
      expect(quiz.finished, isTrue);
      expect(quiz.correctCount, quizQuestions.length);

      quiz.restart();
      expect(quiz.index, 0);
      expect(quiz.correctCount, 0);
    });

    test('cannot advance without answering', () {
      final quiz = QuizViewModel(quizQuestions);
      quiz.next();
      expect(quiz.index, 0);
    });
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('ana@'), isNotNull);
      expect(Validators.email('ana@example.com'), isNull);
      // Rejected by the 2023 regex (TLD > 4 chars, "+" alias):
      expect(Validators.email('ana+doacao@hemocentro.online'), isNull);
    });

    test('password', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password('12345678'), isNull);
    });
  });
}

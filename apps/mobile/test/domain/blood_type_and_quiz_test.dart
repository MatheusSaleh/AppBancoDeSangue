import 'package:appbancodesangue/domain/models/blood_type.dart';
import 'package:appbancodesangue/domain/models/quiz.dart';
import 'package:appbancodesangue/features/quiz/quiz_questions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BloodType red cell compatibility', () {
    // Reference table (donor -> recipients) used in transfusion medicine.
    const expected = {
      'O-': ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'],
      'O+': ['O+', 'A+', 'B+', 'AB+'],
      'A-': ['A-', 'A+', 'AB-', 'AB+'],
      'A+': ['A+', 'AB+'],
      'B-': ['B-', 'B+', 'AB-', 'AB+'],
      'B+': ['B+', 'AB+'],
      'AB-': ['AB-', 'AB+'],
      'AB+': ['AB+'],
    };

    for (final entry in expected.entries) {
      test('${entry.key} can donate to ${entry.value.join(', ')}', () {
        final donor = BloodType.fromLabel(entry.key)!;
        expect(
          donor.canDonateTo.map((t) => t.label),
          unorderedEquals(entry.value),
        );
      });
    }

    test('canReceiveFrom is the inverse relation', () {
      for (final recipient in BloodType.values) {
        for (final donor in BloodType.values) {
          expect(
            recipient.canReceiveFrom.contains(donor),
            donor.canDonateTo.contains(recipient),
          );
        }
      }
    });

    test('AB+ is the universal recipient', () {
      expect(BloodType.abPositive.canReceiveFrom, BloodType.values);
    });

    test('fromLabel handles unknown values', () {
      expect(BloodType.fromLabel('X'), isNull);
      expect(BloodType.fromLabel(null), isNull);
    });
  });

  group('quiz', () {
    test('every question has a valid correct answer and explanation', () {
      for (final q in quizQuestions) {
        expect(q.options.length, greaterThanOrEqualTo(2), reason: q.text);
        expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
        expect(q.explanation, isNotEmpty);
      }
    });

    test('result messages match the original 2023 thresholds', () {
      // Original: +10 per correct, -2 per wrong, thresholds 41/31/21/1.
      expect(quizResultMessage(correct: 5, total: 5), contains('herói'));
      expect(quizResultMessage(correct: 4, total: 5), contains('exemplar'));
      expect(quizResultMessage(correct: 3, total: 5), contains('esforço'));
      expect(quizResultMessage(correct: 2, total: 5), contains('louvável'));
      expect(quizResultMessage(correct: 1, total: 5), contains('louvável'));
      expect(quizResultMessage(correct: 0, total: 5), contains('precisa'));
    });
  });
}

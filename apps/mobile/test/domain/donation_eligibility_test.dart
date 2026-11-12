import 'package:appbancodesangue/domain/models/donation.dart';
import 'package:appbancodesangue/domain/models/donor_profile.dart';
import 'package:appbancodesangue/domain/rules/donation_eligibility.dart';
import 'package:flutter_test/flutter_test.dart';

Donation _d(int year, int month, int day, [String id = '']) => Donation(
  id: id.isEmpty ? '$year-$month-$day' : id,
  date: DateTime(year, month, day),
);

void main() {
  final today = DateTime(2026, 11, 11, 15, 30);

  group('evaluateEligibility', () {
    test('requires sex to apply the rules', () {
      final r = evaluateEligibility(donations: [], sex: null, today: today);
      expect(r.status, EligibilityStatus.profileIncomplete);
      expect(r.canDonate, isFalse);
    });

    test('no history means only clinical screening applies', () {
      final r = evaluateEligibility(
        donations: [],
        sex: BiologicalSex.female,
        today: today,
      );
      expect(r.status, EligibilityStatus.noHistory);
      expect(r.canDonate, isTrue);
    });

    test('men wait 60 days after the last donation', () {
      final r = evaluateEligibility(
        donations: [_d(2026, 10, 1)],
        sex: BiologicalSex.male,
        today: today,
      );
      expect(r.status, EligibilityStatus.waitingInterval);
      expect(r.nextEligibleDate, DateTime(2026, 11, 30));
      expect(r.daysRemaining(today), 19);
    });

    test('women wait 90 days after the last donation', () {
      final r = evaluateEligibility(
        donations: [_d(2026, 10, 1)],
        sex: BiologicalSex.female,
        today: today,
      );
      expect(r.nextEligibleDate, DateTime(2026, 12, 30));
    });

    test('is eligible exactly on the 60th day', () {
      final r = evaluateEligibility(
        donations: [_d(2026, 9, 12)],
        sex: BiologicalSex.male,
        today: today,
      );
      expect(r.status, EligibilityStatus.eligible);
      expect(r.canDonate, isTrue);
      expect(r.donationsInLast12Months, 1);
    });

    test('order of the input list does not matter', () {
      final r = evaluateEligibility(
        donations: [_d(2025, 1, 1), _d(2026, 10, 1), _d(2026, 3, 1)],
        sex: BiologicalSex.male,
        today: today,
      );
      expect(r.lastDonation, DateTime(2026, 10, 1));
    });

    test('women are limited to 3 donations in 12 months', () {
      // Intervals are all >= 90 days, but this would be the 4th in 12 months.
      final r = evaluateEligibility(
        donations: [_d(2026, 1, 5), _d(2026, 4, 10), _d(2026, 7, 20)],
        sex: BiologicalSex.female,
        today: today,
      );
      expect(r.status, EligibilityStatus.waitingYearlyLimit);
      expect(r.donationsInLast12Months, 3);
      // The oldest of the three leaves the window one year later.
      expect(r.nextEligibleDate, DateTime(2027, 1, 5));
    });

    test('men are limited to 4 donations in 12 months', () {
      final r = evaluateEligibility(
        donations: [
          _d(2026, 1, 10),
          _d(2026, 3, 15),
          _d(2026, 5, 20),
          _d(2026, 8, 1),
        ],
        sex: BiologicalSex.male,
        today: today,
      );
      expect(r.status, EligibilityStatus.waitingYearlyLimit);
      expect(r.nextEligibleDate, DateTime(2027, 1, 10));
    });

    test('old donations do not count toward the yearly limit', () {
      final r = evaluateEligibility(
        donations: [_d(2025, 1, 5), _d(2025, 4, 10), _d(2025, 7, 20)],
        sex: BiologicalSex.female,
        today: today,
      );
      expect(r.status, EligibilityStatus.eligible);
      // Window is (2025-11-11, 2026-11-11]: none of them is inside it.
      expect(r.donationsInLast12Months, 0);
    });

    test('future-dated records are ignored', () {
      final r = evaluateEligibility(
        donations: [_d(2027, 1, 1)],
        sex: BiologicalSex.male,
        today: today,
      );
      expect(r.status, EligibilityStatus.noHistory);
    });

    test('interval crossing a month end and leap day', () {
      final r = evaluateEligibility(
        donations: [_d(2028, 1, 15)],
        sex: BiologicalSex.male,
        today: DateTime(2028, 2, 1),
      );
      // 2028 is a leap year: Jan 15 + 60 days = Mar 15.
      expect(r.nextEligibleDate, DateTime(2028, 3, 15));
    });
  });

  group('validateDonationDate', () {
    test('rejects future dates', () {
      expect(
        validateDonationDate(
          date: DateTime(2026, 11, 12),
          today: today,
          existing: [],
          sex: BiologicalSex.male,
        ),
        DonationDateIssue.inFuture,
      );
    });

    test('accepts today', () {
      expect(
        validateDonationDate(
          date: DateTime(2026, 11, 11),
          today: today,
          existing: [],
          sex: BiologicalSex.male,
        ),
        isNull,
      );
    });

    test('flags dates closer than the minimum interval', () {
      expect(
        validateDonationDate(
          date: DateTime(2026, 11, 1),
          today: today,
          existing: [_d(2026, 10, 1)],
          sex: BiologicalSex.male,
        ),
        DonationDateIssue.tooCloseToAnother,
      );
    });

    test('ignores the record being edited', () {
      expect(
        validateDonationDate(
          date: DateTime(2026, 10, 5),
          today: today,
          existing: [_d(2026, 10, 1, 'a')],
          sex: BiologicalSex.male,
          editingId: 'a',
        ),
        isNull,
      );
    });
  });
}

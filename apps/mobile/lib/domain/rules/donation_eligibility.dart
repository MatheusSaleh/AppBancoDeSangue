import '../models/donation.dart';
import '../models/donor_profile.dart';

/// Interval and yearly limits for whole-blood donation in Brazil.
///
/// Source: Ministério da Saúde — "Perguntas Frequentes (FAQ) - Sangue"
/// (https://www.gov.br/saude/pt-br/composicao/saes/sangue/faq):
/// "Homens podem doar sangue de 2 em 2 meses, sendo, no máximo, 4 vezes ao
/// ano. Mulheres podem doar sangue 3 em 3 meses, sendo, no máximo, 3 doações
/// anuais." The original 2023 app expressed the intervals as 60 and 90 days,
/// which is kept here. The yearly cap is applied over a rolling 12-month
/// window, the conservative reading.
class DonationRules {
  const DonationRules({
    required this.minIntervalDays,
    required this.maxPerYear,
  });

  final int minIntervalDays;
  final int maxPerYear;

  static const male = DonationRules(minIntervalDays: 60, maxPerYear: 4);
  static const female = DonationRules(minIntervalDays: 90, maxPerYear: 3);

  static DonationRules forSex(BiologicalSex sex) =>
      sex == BiologicalSex.male ? male : female;
}

enum EligibilityStatus {
  /// No donations registered yet: only clinical screening applies.
  noHistory,

  /// Interval and yearly limit are satisfied.
  eligible,

  /// Must wait for the minimum interval since the last donation.
  waitingInterval,

  /// The yearly limit was reached in the last 12 months.
  waitingYearlyLimit,

  /// Sex is unknown, so the rules cannot be applied.
  profileIncomplete,
}

class EligibilityResult {
  const EligibilityResult({
    required this.status,
    this.nextEligibleDate,
    this.lastDonation,
    this.donationsInLast12Months = 0,
    this.rules,
  });

  final EligibilityStatus status;

  /// First day the user can donate again (null when already eligible or
  /// when it cannot be computed).
  final DateTime? nextEligibleDate;
  final DateTime? lastDonation;
  final int donationsInLast12Months;
  final DonationRules? rules;

  bool get canDonate =>
      status == EligibilityStatus.eligible ||
      status == EligibilityStatus.noHistory;

  /// Days left until [nextEligibleDate], counted from [today].
  int daysRemaining(DateTime today) {
    final next = nextEligibleDate;
    if (next == null) return 0;
    final diff = _dateOnly(next).difference(_dateOnly(today)).inDays;
    return diff < 0 ? 0 : diff;
  }
}

/// Estimates when the donor may donate again based on the registered history.
///
/// This is an educational estimate: clinical screening at the blood center
/// always has the final word.
EligibilityResult evaluateEligibility({
  required List<Donation> donations,
  required BiologicalSex? sex,
  required DateTime today,
}) {
  if (sex == null) {
    return const EligibilityResult(status: EligibilityStatus.profileIncomplete);
  }
  final rules = DonationRules.forSex(sex);
  final todayDay = _dateOnly(today);

  // Most recent first. Future-dated records are ignored defensively.
  final days =
      donations.map((d) => d.day).where((d) => !d.isAfter(todayDay)).toList()
        ..sort((a, b) => b.compareTo(a));

  if (days.isEmpty) {
    return EligibilityResult(status: EligibilityStatus.noHistory, rules: rules);
  }

  final last = days.first;
  final byInterval = _addDays(last, rules.minIntervalDays);

  // With N donations allowed per 12 months, the N-th most recent donation
  // must leave the window before a new one is allowed.
  DateTime? byYearlyLimit;
  if (days.length >= rules.maxPerYear) {
    final nthMostRecent = days[rules.maxPerYear - 1];
    byYearlyLimit = _addMonths(nthMostRecent, 12);
  }

  final windowStart = _addMonths(todayDay, -12);
  final inWindow = days.where((d) => d.isAfter(windowStart)).length;

  final candidates = [byInterval, ?byYearlyLimit];
  final next = candidates.reduce((a, b) => a.isAfter(b) ? a : b);

  if (!next.isAfter(todayDay)) {
    return EligibilityResult(
      status: EligibilityStatus.eligible,
      lastDonation: last,
      donationsInLast12Months: inWindow,
      rules: rules,
    );
  }

  final limitedByYear =
      byYearlyLimit != null && byYearlyLimit.isAfter(byInterval);
  return EligibilityResult(
    status: limitedByYear
        ? EligibilityStatus.waitingYearlyLimit
        : EligibilityStatus.waitingInterval,
    nextEligibleDate: next,
    lastDonation: last,
    donationsInLast12Months: inWindow,
    rules: rules,
  );
}

/// Validation used when registering a new donation.
enum DonationDateIssue { inFuture, tooOld, tooCloseToAnother }

DonationDateIssue? validateDonationDate({
  required DateTime date,
  required DateTime today,
  required List<Donation> existing,
  required BiologicalSex? sex,
  String? editingId,
}) {
  final day = _dateOnly(date);
  if (day.isAfter(_dateOnly(today))) return DonationDateIssue.inFuture;
  if (day.isBefore(DateTime(1950))) return DonationDateIssue.tooOld;
  if (sex != null) {
    final interval = DonationRules.forSex(sex).minIntervalDays;
    for (final other in existing) {
      if (other.id == editingId) continue;
      final gap = other.day.difference(day).inDays.abs();
      if (gap < interval) return DonationDateIssue.tooCloseToAnother;
    }
  }
  return null;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// Using the DateTime constructor keeps calendar arithmetic correct across
// daylight-saving changes (adding Duration(days: n) would not).
DateTime _addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

DateTime _addMonths(DateTime d, int months) {
  final target = DateTime(d.year, d.month + months, 1);
  final lastDay = DateTime(target.year, target.month + 1, 0).day;
  return DateTime(target.year, target.month, d.day > lastDay ? lastDay : d.day);
}

/// ABO/Rh blood groups.
enum BloodType {
  oNegative('O-', _Abo.o, rhPositive: false),
  oPositive('O+', _Abo.o, rhPositive: true),
  aNegative('A-', _Abo.a, rhPositive: false),
  aPositive('A+', _Abo.a, rhPositive: true),
  bNegative('B-', _Abo.b, rhPositive: false),
  bPositive('B+', _Abo.b, rhPositive: true),
  abNegative('AB-', _Abo.ab, rhPositive: false),
  abPositive('AB+', _Abo.ab, rhPositive: true);

  const BloodType(this.label, this._abo, {required this.rhPositive});

  /// Human readable label, e.g. `AB+`.
  final String label;
  final _Abo _abo;
  final bool rhPositive;

  /// Red blood cell compatibility: a donor can give to a recipient when every
  /// ABO antigen of the donor is also present in the recipient and an Rh+
  /// donor only gives to Rh+ recipients.
  bool canDonateRedCellsTo(BloodType recipient) {
    final aboOk = recipient._abo.antigens.containsAll(_abo.antigens);
    final rhOk = !rhPositive || recipient.rhPositive;
    return aboOk && rhOk;
  }

  List<BloodType> get canDonateTo =>
      BloodType.values.where(canDonateRedCellsTo).toList();

  List<BloodType> get canReceiveFrom =>
      BloodType.values.where((d) => d.canDonateRedCellsTo(this)).toList();

  static BloodType? fromLabel(String? label) {
    for (final type in BloodType.values) {
      if (type.label == label) return type;
    }
    return null;
  }
}

enum _Abo {
  o({}),
  a({'A'}),
  b({'B'}),
  ab({'A', 'B'});

  const _Abo(this.antigens);
  final Set<String> antigens;
}

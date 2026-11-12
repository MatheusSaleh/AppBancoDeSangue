/// A whole-blood donation registered by the user.
class Donation {
  const Donation({
    required this.id,
    required this.date,
    this.location = '',
    this.notes = '',
  });

  final String id;

  /// Date of the donation (time of day is not relevant for the rules).
  final DateTime date;

  /// Blood center / hemocentro where the donation happened (optional).
  final String location;
  final String notes;

  DateTime get day => DateTime(date.year, date.month, date.day);

  Donation copyWith({
    String? id,
    DateTime? date,
    String? location,
    String? notes,
  }) {
    return Donation(
      id: id ?? this.id,
      date: date ?? this.date,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Donation &&
      other.id == id &&
      other.date == date &&
      other.location == location &&
      other.notes == notes;

  @override
  int get hashCode => Object.hash(id, date, location, notes);
}

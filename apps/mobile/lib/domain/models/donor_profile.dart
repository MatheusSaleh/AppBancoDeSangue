import 'blood_type.dart';

/// Biological sex as used by the Brazilian donation rules, which define
/// different intervals and yearly limits for men and women.
enum BiologicalSex {
  male('masculino', 'Masculino'),
  female('feminino', 'Feminino');

  const BiologicalSex(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static BiologicalSex? fromStorage(String? value) {
    for (final sex in BiologicalSex.values) {
      if (sex.storageValue == value) return sex;
    }
    return null;
  }
}

class DonorProfile {
  const DonorProfile({this.name = '', this.sex, this.bloodType});

  final String name;
  final BiologicalSex? sex;
  final BloodType? bloodType;

  static const empty = DonorProfile();

  bool get isComplete => name.trim().isNotEmpty && sex != null;

  DonorProfile copyWith({
    String? name,
    BiologicalSex? sex,
    BloodType? bloodType,
  }) {
    return DonorProfile(
      name: name ?? this.name,
      sex: sex ?? this.sex,
      bloodType: bloodType ?? this.bloodType,
    );
  }

  Map<String, Object?> toJson() => {
    'nome': name,
    'sexo': sex?.storageValue,
    'tipo_sanguineo': bloodType?.label,
  };

  factory DonorProfile.fromJson(Map<String, Object?> json) {
    return DonorProfile(
      name: (json['nome'] as String?) ?? '',
      sex: BiologicalSex.fromStorage(json['sexo'] as String?),
      bloodType: BloodType.fromLabel(json['tipo_sanguineo'] as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DonorProfile &&
      other.name == name &&
      other.sex == sex &&
      other.bloodType == bloodType;

  @override
  int get hashCode => Object.hash(name, sex, bloodType);
}

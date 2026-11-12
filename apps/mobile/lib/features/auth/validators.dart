/// Form validators shared by the auth screens. They return a message in
/// Portuguese or null when the value is valid.
abstract final class Validators {
  // Pragmatic check; the backend performs the authoritative validation.
  // Unlike the 2023 regex, accepts long TLDs (.online) and "+" aliases.
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static const minPasswordLength = 8;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Informe seu e-mail.';
    if (!_email.hasMatch(v)) return 'E-mail inválido.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Informe sua senha.';
    if (v.length < minPasswordLength) {
      return 'A senha deve ter pelo menos $minPasswordLength caracteres.';
    }
    return null;
  }

  static String? required(String? value, String field) =>
      (value?.trim().isEmpty ?? true) ? 'Informe $field.' : null;
}

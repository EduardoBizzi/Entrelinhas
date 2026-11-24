class Validators {
  static String? requiredText(String? value, {String field = 'este campo'}) =>
      value == null || value.trim().isEmpty ? 'Preencha $field.' : null;

  static String? fullName(String? value) {
    if (value == null || value.trim().split(RegExp(r'\s+')).length < 2) {
      return 'Informe seu nome e sobrenome.';
    }
    return null;
  }

  static String? email(String? value) =>
      value != null &&
          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
      ? null
      : 'Informe um e-mail válido.';

  static String? password(String? value) =>
      value == null || value.length < 6 ? 'Use pelo menos 6 caracteres.' : null;
}

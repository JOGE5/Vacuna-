class Validators {
  static String? required(String? v) =>
      v == null || v.trim().isEmpty ? 'Este campo es obligatorio' : null;
  static String? email(String? v) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v?.trim() ?? '')
      ? null
      : 'Introduce un correo válido';
  static String? password(String? v) =>
      (v?.length ?? 0) < 6 ? 'Usa al menos 6 caracteres' : null;
  static String? positive(String? v) => (int.tryParse(v ?? '') ?? 0) <= 0
      ? 'Introduce un entero mayor que cero'
      : null;
  static String? phone(String? v) =>
      (v?.trim().isEmpty ?? true) || RegExp(r'^\+?[\d\s-]{7,20}$').hasMatch(v!)
      ? null
      : 'Introduce un teléfono válido';
  static String? document(String? v) =>
      RegExp(r'^[\w\s-]{5,25}$').hasMatch(v?.trim() ?? '')
      ? null
      : 'Introduce un documento válido (5–25 caracteres)';
}

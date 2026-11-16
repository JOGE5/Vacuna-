import '../models/entities.dart';

/// Error de inicio de sesión con un mensaje listo para mostrar.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Contrato de autenticación. Hoy se usa [LocalAuthService]; para conectar
/// Supabase basta con otra implementación de esta clase pasada a
/// `AppStore(auth: ...)`, sin cambiar las pantallas.
abstract class AuthService {
  /// Devuelve el usuario autenticado o lanza [AuthException].
  Future<AppUser> signIn(String email, String password);

  /// Acceso de ciudadanos con su cuenta de Google (vista de puntos de
  /// vacunación). Devuelve el usuario o lanza [AuthException].
  Future<AppUser> signInWithGoogle();
  Future<void> signOut();
}

/// Credenciales locales de demostración, sin base de datos.
/// Se reemplaza por la implementación de Supabase cuando esté lista.
class LocalAuthService implements AuthService {
  const LocalAuthService();
  static const credentials = [
    (
      id: 'ana-torres',
      email: 'ana.torres@example.com',
      password: 'salud123',
      name: 'Ana Torres',
      role: 'Personal de salud',
    ),
    (
      id: 'carlos-rojas',
      email: 'carlos.rojas@example.com',
      password: 'admin123',
      name: 'Carlos Rojas',
      role: 'Administrador',
    ),
    (
      id: 'elena-vargas',
      email: 'elena.vargas@example.com',
      password: 'salud123',
      name: 'Elena Vargas',
      role: 'Personal de salud',
    ),
  ];

  @override
  Future<AppUser> signIn(String email, String password) async {
    final key = email.trim().toLowerCase();
    final match = credentials.where(
      (c) => c.email == key && c.password == password,
    );
    if (match.isEmpty) {
      throw const AuthException('Correo o contraseña incorrectos');
    }
    final c = match.first;
    return AppUser(c.name, c.email, c.role, true, id: c.id);
  }

  // Google necesita un servidor de autenticación; llega con Supabase.
  @override
  Future<AppUser> signInWithGoogle() async => throw const AuthException(
    'El acceso con Google se activa al conectar Supabase. '
    'Por ahora puedes entrar como invitado.',
  );

  @override
  Future<void> signOut() async {}
}

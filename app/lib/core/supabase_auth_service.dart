import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/entities.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

/// Autenticación real; los permisos del personal vienen de public.perfiles,
/// nunca del correo ni de metadatos editables del usuario.
class SupabaseAuthService implements AuthService {
  const SupabaseAuthService();

  SupabaseClient get _client => VacunaSupabase.client;

  Future<AppUser?> currentUser() async {
    final user = _client.auth.currentUser;
    return user == null ? null : _fromUser(user);
  }

  Future<AppUser> _fromUser(User user) async {
    final profile = await _client
        .from('perfiles')
        .select('nombre, correo, rol, activo')
        .eq('id', user.id)
        .maybeSingle();
    final role = profile?['rol'] as String? ?? 'Ciudadano';
    final active = profile?['activo'] as bool? ?? true;
    final name = (profile?['nombre'] as String?) ??
        (user.userMetadata?['full_name'] as String?) ??
        user.email?.split('@').first ??
        'Ciudadano';
    return AppUser(
      name,
      (profile?['correo'] as String?) ?? user.email ?? '',
      role,
      active,
      id: user.id,
    );
  }

  @override
  Future<AppUser> signIn(String email, String password) async {
    try {
      final result = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = result.user;
      if (user == null) {
        throw const AuthException('No se pudo iniciar sesión.');
      }
      final account = await _fromUser(user);
      if (!account.active) {
        await _client.auth.signOut();
        throw const AuthException('Tu cuenta está inactiva.');
      }
      if (account.role == 'Ciudadano') {
        await _client.auth.signOut();
        throw const AuthException(
          'Esta pantalla es para personal autorizado. Usa Google para acceder como ciudadano.',
        );
      }
      return account;
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('No se pudo iniciar sesión: $e');
    }
  }

  /// En web, OAuth redirige el navegador y la sesión se recibe después.
  /// El listener del AppStore completa el acceso al volver de Google.
  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      final started = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? Uri.base.origin : 'io.supabase.vacunaplus://login-callback/',
      );
      if (!started) {
        throw const AuthException('No se pudo abrir el inicio de sesión con Google.');
      }
      // OAuth web regresa de forma asíncrona; la sesión se procesa al volver.
      return AppUser('Iniciando sesión', '', 'Ciudadano', true);
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw AuthException('No se pudo iniciar sesión con Google: $e');
    }
  }

  @override
  Future<void> signOut() => _client.auth.signOut();
}

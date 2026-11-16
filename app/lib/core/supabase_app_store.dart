import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/entities.dart';
import 'app_store.dart';
import 'supabase_auth_service.dart';
import 'supabase_config.dart';

/// Estado de sesión real para producción. El AppStore de demostración se
/// mantiene intacto para las pruebas existentes y la rama principal.
class SupabaseAppStore extends AppStore {
  SupabaseAppStore() : super(auth: const SupabaseAuthService()) {
    _authSubscription = VacunaSupabase.client.auth.onAuthStateChange.listen(
      (event) {
        if (event.event == AuthChangeEvent.signedOut) {
          ++_request;
          _account = null;
          _guest = false;
          notifyListeners();
        } else if (event.session != null) {
          _restore();
        }
      },
    );
    _restore();
  }

  StreamSubscription<AuthState>? _authSubscription;
  AppUser? _account;
  bool _guest = false;
  int _request = 0;

  @override
  bool get signedIn => _account != null || _guest;

  @override
  bool get isGuest => _guest;

  @override
  AppUser get currentUser => _account ??
      (_guest
          ? AppUser('Invitado', '', AppStore.guestRole, true)
          : super.currentUser);

  Future<void> _restore() async {
    final request = ++_request;
    try {
      final account = await (auth as SupabaseAuthService).currentUser();
      if (request != _request) return;
      if (account != null && !account.active) {
        await auth.signOut();
        return;
      }
      _account = account;
      _guest = false;
      notifyListeners();
    } catch (e) {
      debugPrint('No se pudo recuperar la sesión: $e');
    }
  }

  @override
  Future<void> signIn(String email, String password) async {
    final account = await auth.signIn(email, password);
    ++_request;
    _account = account;
    _guest = false;
    notifyListeners();
  }

  @override
  Future<void> signInWithGoogle() async {
    // OAuth redirige a Google. La sesión llega al volver mediante el listener.
    await auth.signInWithGoogle();
  }

  @override
  void enterAsGuest() {
    ++_request;
    _account = null;
    _guest = true;
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    ++_request;
    await auth.signOut();
    _account = null;
    _guest = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

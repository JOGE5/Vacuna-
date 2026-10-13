import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/auth_service.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../widgets/common.dart';
import '../widgets/page_shell.dart';
import '../widgets/form_fields.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController();
  bool hidden = true, loading = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit(AppStore s) async {
    if (loading || !form.currentState!.validate()) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await s.signIn(email.text, password.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _openCitizenView() =>
      Navigator.pushNamedAndRemoveUntil(context, '/explorar', (r) => false);

  Future<void> _google(AppStore s) async {
    try {
      await s.signInWithGoogle();
      if (mounted) _openCitizenView();
    } on AuthException catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return PageShell(
      child: Column(
        children: [
          const Brand(large: true),
          const SizedBox(height: 14),
          Image.asset(
            'assets/images/equipo_medico.png',
            height: 210,
            fit: BoxFit.contain,
          ),
          const Text(
            'Cuidamos juntos',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          gap,
          Panel(
            padding: 20,
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InputField(
                    'Correo electrónico',
                    email,
                    validator: Validators.email,
                    icon: Icons.mail_outline,
                    keyboard: TextInputType.emailAddress,
                  ),
                  const Text(
                    'Contraseña',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: password,
                    obscureText: hidden,
                    validator: Validators.password,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => hidden = !hidden),
                        icon: Icon(
                          hidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Recuperar contraseña'),
                          content: const Text(
                            'Esta es una demostración local. Introduce un correo válido; el envío de recuperación requiere conectar un servicio de autenticación.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text('Entendido'),
                            ),
                          ],
                        ),
                      ),
                      child: const Text('Olvidé mi contraseña'),
                    ),
                  ),
                  if (error != null) Notice(error!, warning: true),
                  ActionButton(
                    loading ? 'Ingresando…' : 'Ingresar',
                    () => _submit(s),
                    icon: Icons.login,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '¿Buscas dónde vacunarte?',
                  style: TextStyle(color: muted),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
          gap,
          ActionButton(
            'Continuar con Google',
            () => _google(s),
            icon: Icons.account_circle_outlined,
            outlined: true,
          ),
          gap,
          ActionButton(
            'Entrar como invitado',
            () {
              s.enterAsGuest();
              _openCitizenView();
            },
            icon: Icons.explore_outlined,
            outlined: true,
          ),
        ],
      ),
    );
  }
}

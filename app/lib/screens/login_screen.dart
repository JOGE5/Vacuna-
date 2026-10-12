import 'package:flutter/material.dart';
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
  bool hidden = true;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageShell(
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
                ActionButton('Ingresar', () {
                  if (form.currentState!.validate()) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (r) => false,
                    );
                  }
                }, icon: Icons.login),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

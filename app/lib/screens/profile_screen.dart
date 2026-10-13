import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/page_shell.dart';
import '../widgets/editor_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context), u = s.currentUser;
    void info(String title, String text) => showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    Future<void> edit() async {
      final v = await editorDialog(
        context,
        'Editar perfil',
        const ['Nombre', 'Correo'],
        initial: {'Nombre': u.name, 'Correo': u.email},
      );
      if (v != null && context.mounted) {
        if (s.users.any(
          (other) =>
              other != u &&
              other.email.toLowerCase() == v['Correo']!.toLowerCase(),
        )) {
          toast(context, 'Este correo ya está registrado');
          return;
        }
        u.name = v['Nombre']!;
        u.email = v['Correo']!;
        s.changed();
      }
    }

    return PageShell(
      title: 'Mi perfil',
      back: true,
      navIndex: 3,
      child: Column(
        children: [
          Panel(
            child: Column(
              children: [
                Row(
                  children: [
                    CircleMark(text: u.initials, size: 72),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.name,
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            u.role,
                            style: const TextStyle(
                              color: green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Row(
                            children: [
                              Icon(
                                Icons.business_outlined,
                                size: 16,
                                color: green,
                              ),
                              SizedBox(width: 6),
                              Text('Centro San Martín'),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.mail_outline,
                                size: 16,
                                color: green,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  u.email,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                gap,
                ActionButton('Editar perfil', edit, icon: Icons.edit_outlined),
              ],
            ),
          ),
          _group('Mi cuenta', [
            ListTile(
              leading: const Icon(Icons.person_outline, color: green),
              title: const Text('Datos personales'),
              trailing: const Icon(Icons.chevron_right),
              onTap: edit,
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: green),
              title: const Text('Cambiar contraseña'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => info(
                'Cambiar contraseña',
                'El cambio de contraseña requiere autenticación real. En esta entrega el acceso es de demostración.',
              ),
            ),
          ]),
          _group('Preferencias', [
            SwitchListTile(
              secondary: const Icon(Icons.notifications_none, color: green),
              title: const Text('Notificaciones'),
              value: s.notifications,
              onChanged: (v) {
                s.notifications = v;
                s.changed();
              },
            ),
            ListTile(
              leading: const Icon(Icons.language, color: green),
              title: const Text('Idioma'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => info(
                'Idioma',
                'Español. Las interfaces de esta entrega están en español.',
              ),
            ),
          ]),
          _group('Ayuda', [
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: green),
              title: const Text('Soporte'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => info(
                'Soporte',
                'Consulta README.md para ejecutar la aplicación y probar las validaciones.',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined, color: green),
              title: const Text('Privacidad'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => info(
                'Privacidad',
                'Los datos son ficticios y se guardan solo en memoria durante la sesión. No se envían a un servidor.',
              ),
            ),
          ]),
          Panel(
            child: TextButton.icon(
              onPressed: () async {
                await s.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(String title, List<Widget> rows) => Panel(
    padding: 8,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            title,
            style: const TextStyle(color: green, fontWeight: FontWeight.bold),
          ),
        ),
        ...rows,
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/theme.dart';
import '../models/entities.dart';
import '../widgets/common.dart';
import '../widgets/page_shell.dart';
import '../widgets/editor_dialog.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String query = '', tab = 'Todos';
  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context),
        list = s.users.where(
          (u) =>
              '${u.name} ${u.email}'.toLowerCase().contains(
                query.toLowerCase(),
              ) &&
              (tab == 'Todos' || (tab == 'Activos') == u.active),
        );
    return PageShell(
      title: 'Usuarios',
      back: true,
      navIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Administración', style: TextStyle(color: muted)),
          gap,
          SearchBox(
            'Buscar por nombre o correo',
            (v) => setState(() => query = v),
          ),
          Tabs(
            const ['Todos', 'Activos', 'Inactivos'],
            tab,
            (v) => setState(() => tab = v),
          ),
          ...list.map(
            (u) => Panel(
              child: Row(
                children: [
                  CircleMark(text: u.initials, size: 50),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          u.email,
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                        Text(
                          u.role,
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'state') {
                            u.active = !u.active;
                            s.changed();
                          } else {
                            final values = await editorDialog(
                              context,
                              'Editar usuario',
                              const ['Nombre', 'Correo'],
                              initial: {'Nombre': u.name, 'Correo': u.email},
                            );
                            if (values != null && context.mounted) {
                              if (s.users.any(
                                (other) =>
                                    other != u &&
                                    other.email.toLowerCase() ==
                                        values['Correo']!.toLowerCase(),
                              )) {
                                toast(
                                  context,
                                  'Este correo ya está registrado',
                                );
                                return;
                              }
                              u.name = values['Nombre']!;
                              u.email = values['Correo']!;
                              s.changed();
                            }
                          }
                        },
                        itemBuilder: (c) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Editar'),
                          ),
                          PopupMenuItem(
                            value: 'state',
                            child: Text(u.active ? 'Desactivar' : 'Activar'),
                          ),
                        ],
                      ),
                      StatusBadge(u.active ? 'Activo' : 'Inactivo'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (list.isEmpty) const Notice('No se encontraron usuarios'),
          ActionButton('Crear usuario', () async {
            final v = await editorDialog(context, 'Crear usuario', const [
              'Nombre',
              'Correo',
            ]);
            if (v != null && context.mounted) {
              if (s.users.any(
                (u) => u.email.toLowerCase() == v['Correo']!.toLowerCase(),
              )) {
                toast(context, 'Este correo ya está registrado');
                return;
              }
              s.users.add(
                AppUser(v['Nombre']!, v['Correo']!, 'Personal de salud', true),
              );
              s.changed();
              toast(context, 'Usuario creado');
            }
          }, icon: Icons.add_circle_outline),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../widgets/page_shell.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context) => PageShell(
    title: 'Más',
    navIndex: 3,
    child: Column(
      children: [
        const Brand(),
        gap,
        ...[
          ('Inventario de vacunas', Icons.medication_outlined, '/inventory'),
          ('Centros de vacunación', Icons.location_on_outlined, '/centers'),
          ('Reportes y estadísticas', Icons.bar_chart, '/reports'),
          ('Gestión de usuarios', Icons.people_outline, '/users'),
          ('Perfil / Configuración', Icons.settings_outlined, '/profile'),
        ].map(
          (e) => Panel(
            child: ListTile(
              leading: CircleMark(icon: e.$2),
              title: Text(e.$1),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => go(context, e.$3),
            ),
          ),
        ),
      ],
    ),
  );
}

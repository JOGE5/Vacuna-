import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/theme.dart';
import '../models/entities.dart';
import '../widgets/centers_map.dart';
import '../widgets/common.dart';
import '../widgets/page_shell.dart';
import '../widgets/editor_dialog.dart';

class CentersScreen extends StatefulWidget {
  const CentersScreen({super.key});
  @override
  State<CentersScreen> createState() => _CentersScreenState();
}

class _CentersScreenState extends State<CentersScreen> {
  String query = '', tab = 'Lista';
  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context),
        list = s.centers.where(
          (e) => '${e.name} ${e.address}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        );
    return PageShell(
      title: 'Centros de vacunación',
      back: true,
      navIndex: 3,
      child: Column(
        children: [
          SearchBox('Buscar centro o zona', (v) => setState(() => query = v)),
          Tabs(const ['Lista', 'Mapa'], tab, (v) => setState(() => tab = v)),
          if (tab == 'Mapa') ...[
            CentersMap(
              centers: list.toList(),
              onSelect: (c) => showCenterSheet(context, s, c),
            ),
            const SizedBox(height: 10),
            const Notice('Toca un marcador para ver el centro y cómo llegar.'),
          ],
          ...list.map(
            (e) => Panel(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleMark(icon: Icons.location_on_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              e.address,
                              style: const TextStyle(
                                fontSize: 12,
                                color: muted,
                              ),
                            ),
                            Text(
                              '◷ ${e.hours}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(e.open ? 'Abierto' : 'Cerrado'),
                    ],
                  ),
                  const Divider(color: Color(0xFFE5EDE7)),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => openDirections(context, e),
                          icon: const Icon(Icons.directions_outlined, size: 18),
                          label: const Text('Cómo llegar'),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => go(context, '/campaigns'),
                          icon: const Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                          ),
                          label: const Text('Ver campañas'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (list.isEmpty) const Notice('No se encontraron centros'),
          ActionButton('Añadir centro', () async {
            final v = await editorDialog(context, 'Añadir centro', const [
              'Nombre',
              'Dirección',
              'Horario',
            ]);
            if (v == null || !context.mounted) return;
            final point = await pickLocation(context);
            if (point == null || !context.mounted) return;
            s.centers.add(
              VaccinationCenter(
                v['Nombre']!,
                v['Dirección']!,
                v['Horario']!,
                true,
                lat: point.latitude,
                lng: point.longitude,
              ),
            );
            s.changed();
            toast(context, 'Centro añadido');
          }, icon: Icons.add_circle_outline),
        ],
      ),
    );
  }
}

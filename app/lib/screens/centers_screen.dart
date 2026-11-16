import 'dart:async';
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
  late final Timer clock;

  @override
  void initState() {
    super.initState();
    clock = Timer.periodic(const Duration(minutes: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    clock.cancel();
    super.dispose();
  }

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
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule_outlined,
                                  size: 16,
                                  color: muted,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    e.hours,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        e.isOpenAt(DateTime.now()) ? 'Abierto' : 'Cerrado',
                      ),
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
              'Teléfono',
            ]);
            if (v == null || !context.mounted) return;
            final schedule = await _chooseSchedule(context);
            if (schedule == null || !context.mounted) return;
            final point = await pickLocation(context);
            if (point == null || !context.mounted) return;
            s.centers.add(
              VaccinationCenter(
                v['Nombre']!,
                v['Dirección']!,
                schedule.label,
                weekdays: schedule.weekdays,
                opensAt: schedule.opensAt,
                closesAt: schedule.closesAt,
                phone: v['Teléfono']!,
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

class _CenterSchedule {
  const _CenterSchedule(this.weekdays, this.opensAt, this.closesAt, this.label);
  final Set<int> weekdays;
  final int opensAt, closesAt;
  final String label;
}

Future<_CenterSchedule?> _chooseSchedule(BuildContext context) {
  final days = <int>{1, 2, 3, 4, 5};
  var opening = const TimeOfDay(hour: 8, minute: 0);
  var closing = const TimeOfDay(hour: 17, minute: 0);
  String? error;
  String time(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  int minutes(TimeOfDay value) => value.hour * 60 + value.minute;
  return showDialog<_CenterSchedule>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Horario de atención'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Días de atención'),
              Wrap(
                spacing: 4,
                children: [
                  for (var day = 1; day <= 7; day++)
                    FilterChip(
                      label: Text(
                        ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][day -
                            1],
                      ),
                      selected: days.contains(day),
                      onSelected: (selected) => setDialogState(() {
                        if (selected) {
                          days.add(day);
                        } else {
                          days.remove(day);
                        }
                      }),
                    ),
                ],
              ),
              TextButton.icon(
                onPressed: () async {
                  final value = await showTimePicker(
                    context: context,
                    initialTime: opening,
                  );
                  if (value != null) setDialogState(() => opening = value);
                },
                icon: const Icon(Icons.schedule),
                label: Text('Abre: ${time(opening)}'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final value = await showTimePicker(
                    context: context,
                    initialTime: closing,
                  );
                  if (value != null) setDialogState(() => closing = value);
                },
                icon: const Icon(Icons.schedule),
                label: Text('Cierra: ${time(closing)}'),
              ),
              if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (days.isEmpty || minutes(opening) >= minutes(closing)) {
                setDialogState(
                  () => error =
                      'Elige días y una hora de cierre posterior a la apertura.',
                );
                return;
              }
              final labels = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
              final dayLabel =
                  days.length == 5 && days.containsAll({1, 2, 3, 4, 5})
                  ? 'Lun–Vie'
                  : days.length == 6 && days.containsAll({1, 2, 3, 4, 5, 6})
                  ? 'Lun–Sáb'
                  : [
                      for (final day in days.toList()..sort()) labels[day - 1],
                    ].join(', ');
              Navigator.pop(
                context,
                _CenterSchedule(
                  Set.of(days),
                  minutes(opening),
                  minutes(closing),
                  '$dayLabel · ${time(opening)}–${time(closing)}',
                ),
              );
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../models/entities.dart';
import '../widgets/common.dart';
import '../widgets/page_shell.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});
  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  String center = 'Todos';
  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final items =
        s.todayAppointments
            .where((a) => center == 'Todos' || a.center == center)
            .toList()
          ..sort((a, b) => a.slot.compareTo(b.slot));
    return PageShell(
      title: 'Turnos de hoy',
      back: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: center,
            decoration: const InputDecoration(labelText: 'Centro'),
            items: [
              'Todos',
              ...s.centers.map((c) => c.name),
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => center = v!),
          ),
          gap,
          if (items.isEmpty) const Notice('No hay turnos para hoy.'),
          for (final group in _groups(items)) ...[
            Text(
              group.key,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            gap,
            for (final a in group.value)
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${a.document} · ${a.vaccine} · ${a.code}'),
                    Text(a.center),
                    if (a.attended)
                      const StatusBadge('Atendido')
                    else
                      TextButton.icon(
                        onPressed: () {
                          s.prepareAppointment(a);
                          go(context, '/vaccination');
                        },
                        icon: const Icon(Icons.vaccines_outlined),
                        label: const Text('Atender'),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Iterable<MapEntry<String, List<Appointment>>> _groups(
    List<Appointment> items,
  ) sync* {
    final groups = <String, List<Appointment>>{};
    for (final a in items) {
      final key =
          '${a.slot.hour.toString().padLeft(2, '0')}:${a.slot.minute.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(a);
    }
    yield* groups.entries;
  }
}

import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/page_shell.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final now = s.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayCount = s.vaccinations
        .where((v) => DateTime(v.date.year, v.date.month, v.date.day) == today)
        .length;
    final pending = s.vaccinations
        .where((v) => v.next != null && !v.next!.isBefore(today))
        .length;
    final upcoming = s.campaigns.where((c) => c.status == 'Próxima').toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final alerts = s.lowStockCount + s.expiringStockCount;
    return PageShell(
      navIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Brand(),
          gap,
          Row(
            children: [
              CircleMark(text: s.currentUser.initials),
              const SizedBox(width: 12),
              Text(
                'Hola, ${s.currentUser.name.split(' ').first}',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Ver alertas',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Notificaciones'),
                    content: Text(
                      alerts == 0
                          ? 'No hay alertas de inventario.'
                          : 'Existencias bajas: ${s.lowStockCount}\nLotes por vencer: ${s.expiringStockCount}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
                icon: const Icon(Icons.notifications_none),
              ),
              StatusBadge(
                alerts == 0
                    ? 'Sin alertas'
                    : '$alerts ${alerts == 1 ? 'alerta' : 'alertas'}',
              ),
            ],
          ),
          gap,
          SizedBox(
            width: double.infinity,
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vacunaciones realizadas hoy',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  gap,
                  Text(
                    '$todayCount',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => go(context, '/turnos'),
            child: Panel(
              child: Row(
                children: [
                  const CircleMark(icon: Icons.event_available_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Turnos de hoy: ${s.todayAppointments.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _stat(
                '${s.campaigns.where((c) => c.status == 'Activa').length}',
                'campañas\nactivas',
                Icons.campaign_outlined,
              ),
              const SizedBox(width: 8),
              _stat(
                '${s.patients.length}',
                'pacientes\nregistrados',
                Icons.people_outline,
              ),
              const SizedBox(width: 8),
              _stat(
                '$pending',
                'citas\npendientes',
                Icons.calendar_month_outlined,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  'Registrar\nvacunación',
                  () => go(context, '/vaccination'),
                  icon: Icons.vaccines_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionButton(
                  'Nuevo\npaciente',
                  () => go(context, '/patient/new'),
                  icon: Icons.person_add_outlined,
                ),
              ),
            ],
          ),
          gap,
          if (upcoming.isNotEmpty)
            InkWell(
              onTap: () {
                s.selectedCampaign = upcoming.first;
                go(context, '/campaign/detail');
              },
              child: Panel(
                child: Row(
                  children: [
                    const CircleMark(icon: Icons.vaccines_outlined, size: 54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Próxima campaña',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            upcoming.first.name,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${dateLabel(upcoming.first.start)} · ${upcoming.first.center}',
                            style: const TextStyle(fontSize: 12, color: muted),
                          ),
                        ],
                      ),
                    ),
                    const StatusBadge('Próxima'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, IconData icon) => Expanded(
    child: Panel(
      padding: 10,
      child: Column(
        children: [
          Icon(icon, color: green),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 23,
              color: green,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ),
    ),
  );
}

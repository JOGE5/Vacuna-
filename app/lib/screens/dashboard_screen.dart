import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/page_shell.dart';
import '../widgets/charts.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return PageShell(
      navIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Brand(),
          gap,
          Row(
            children: [
              const CircleMark(text: 'A'),
              const SizedBox(width: 12),
              Text(
                'Hola, ${s.users.first.name.split(' ').first}',
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Notificaciones'),
                    content: const Text(
                      '• Próxima campaña: Refuerzo infantil\n• Existencias bajas: SRP\n• Lote SRP-2602 próximo a vencer',
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
              const StatusBadge('3 nuevas'),
            ],
          ),
          gap,
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vacunaciones realizadas hoy',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                gap,
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${48 + s.vaccinations.length - 2}',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          '↑ +12% frente a ayer',
                          style: TextStyle(
                            fontSize: 11,
                            color: green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    const Expanded(child: TrendChart()),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              _stat(
                '${6 + s.campaigns.length - 3}',
                'campañas\nactivas',
                Icons.campaign_outlined,
              ),
              const SizedBox(width: 8),
              _stat(
                '${1248 + s.patients.length - 3}',
                'pacientes\nregistrados',
                Icons.people_outline,
              ),
              const SizedBox(width: 8),
              _stat('14', 'citas\npendientes', Icons.calendar_month_outlined),
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
          InkWell(
            onTap: () {
              s.selectedCampaign = s.campaigns[1];
              go(context, '/campaign/detail');
            },
            child: const Panel(
              child: Row(
                children: [
                  CircleMark(icon: Icons.vaccines_outlined, size: 54),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Próxima campaña',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Refuerzo infantil',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '18 oct 2026 · Centro Norte',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge('Próxima'),
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
            style: const TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ),
    ),
  );
}

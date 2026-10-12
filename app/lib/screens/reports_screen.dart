import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/page_shell.dart';
import '../widgets/charts.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String period = 'Período', campaign = 'Campaña', center = 'Centro';
  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final filtered =
        period != 'Período' || campaign != 'Campaña' || center != 'Centro';
    final rows = s.vaccinations.where(
      (v) =>
          (period != 'Este mes' || v.date.year == 2026 && v.date.month == 10) &&
          (center == 'Centro' || v.center == center) &&
          (campaign == 'Campaña' ||
              v.vaccine.contains(
                s.campaigns
                    .firstWhere((c) => c.name == campaign)
                    .vaccine
                    .split(' ')
                    .first,
              )),
    );
    final total = filtered ? rows.length : 480 + s.vaccinations.length - 2;
    return PageShell(
      title: 'Reportes',
      back: true,
      navIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de vacunación',
            style: TextStyle(color: muted, fontSize: 15),
          ),
          gap,
          Row(
            children: [
              Expanded(
                child: SelectField(
                  'Período',
                  const ['Período', 'Este mes', 'Todo el historial'],
                  period,
                  (v) => setState(() => period = v!),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: SelectField(
                  'Campaña',
                  ['Campaña', ...s.campaigns.map((e) => e.name)],
                  campaign,
                  (v) => setState(() => campaign = v!),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: SelectField(
                  'Centro',
                  ['Centro', ...s.centers.map((e) => e.name)],
                  center,
                  (v) => setState(() => center = v!),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _stat('$total', 'Dosis aplicadas', Icons.vaccines_outlined),
              const SizedBox(width: 8),
              _stat(
                '${filtered ? rows.map((v) => v.patient).toSet().length : 420}',
                'Personas atendidas',
                Icons.person_outline,
              ),
              const SizedBox(width: 8),
              _stat(
                '${filtered
                    ? campaign == 'Campaña'
                          ? 0
                          : 1
                    : 6}',
                'Campañas realizadas',
                Icons.health_and_safety_outlined,
              ),
            ],
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Dosis por semana',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text('Total: $total', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                gap,
                WeeklyBars(
                  values: filtered
                      ? [0, 0, 0, rows.length]
                      : const [100, 120, 110, 150],
                ),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Dosis por vacuna',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text('Total: $total', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                gap,
                ...['Influenza', 'COVID-19', 'SRP'].asMap().entries.map((e) {
                  final count = filtered
                      ? rows.where((v) => v.vaccine.startsWith(e.value)).length
                      : [240, 160, 80][e.key];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 75,
                          child: Text(
                            e.value,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: total == 0
                                ? 0
                                : (count / total).clamp(0.0, 1.0),
                            minHeight: 10,
                            color: [ink, green, const Color(0xFF9BD3BC)][e.key],
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('$count', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          if (filtered)
            const Notice(
              'Los filtros consultan los registros de esta demostración. El resumen inicial reproduce las cifras del mockup.',
            ),
        ],
      ),
    );
  }

  Widget _stat(String n, String label, IconData icon) => Expanded(
    child: Panel(
      padding: 10,
      child: Column(
        children: [
          CircleMark(icon: icon),
          gap,
          Text(
            n,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 26,
              color: green,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

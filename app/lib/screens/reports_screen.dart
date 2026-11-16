import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../models/entities.dart';
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
    final now = DateTime.now();
    final rows = s.vaccinations
        .where(
          (v) =>
              (period != 'Este mes' ||
                  v.date.year == now.year && v.date.month == now.month) &&
              (center == 'Centro' || v.center == center) &&
              (campaign == 'Campaña' || v.campaign?.name == campaign),
        )
        .toList();
    final total = rows.length;
    final campaignCount = rows
        .map((v) => v.campaign)
        .whereType<Campaign>()
        .toSet()
        .length;
    final weeks = List<int>.filled(4, 0);
    final firstDay = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 27));
    for (final v in rows) {
      final day = DateTime(v.date.year, v.date.month, v.date.day);
      final offset = day.difference(firstDay).inDays;
      if (offset >= 0 && offset < 28) weeks[offset ~/ 7]++;
    }
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
                '${rows.map((v) => v.patient).toSet().length}',
                'Personas atendidas',
                Icons.person_outline,
              ),
              const SizedBox(width: 8),
              _stat(
                '$campaignCount',
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
                        'Dosis en las últimas 4 semanas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      'Total: ${weeks.fold<int>(0, (a, b) => a + b)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                gap,
                if (weeks.every((n) => n == 0))
                  const Notice('Sin dosis registradas en las últimas 4 semanas')
                else
                  WeeklyBars(values: weeks),
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
                ...rows
                    .map((v) => v.vaccine)
                    .toSet()
                    .toList()
                    .asMap()
                    .entries
                    .map((e) {
                      final count = rows
                          .where((v) => v.vaccine == e.value)
                          .length;
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
                                color: [
                                  ink,
                                  green,
                                  const Color(0xFF9BD3BC),
                                ][e.key % 3],
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$count',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }),
              ],
            ),
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

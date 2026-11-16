import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/page_shell.dart';
import '../core/forecasts.dart';

class CampaignDetailScreen extends StatelessWidget {
  const CampaignDetailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context), c = s.selectedCampaign!;
    final progress = (c.applied / c.goal).clamp(0.0, 1.0);
    final pace = s.pace(c);
    final today = dayOf(s.now());
    final daily = List.generate(14, (i) {
      final day = today.subtract(Duration(days: 13 - i));
      return s.vaccinations
          .where((v) => v.campaign == c && dayOf(v.date) == day)
          .length;
    });
    return PageShell(
      back: true,
      title: '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Brand()),
          gap,
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: const TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    gap,
                    StatusBadge(c.status),
                    gap,
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: muted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${dateLabel(c.start)} – ${dateLabel(c.end)}',
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const ThemeIllustration(
                'assets/images/vacuna.png',
                width: 120,
                height: 140,
              ),
            ],
          ),
          gap,
          Panel(
            child: Column(
              children: [
                _row(Icons.vaccines_outlined, 'Vacuna:', c.vaccine),
                _row(Icons.location_on_outlined, 'Lugar:', c.center),
                _row(Icons.people_outline, 'Población objetivo:', c.target),
                _row(Icons.person_outline, 'Responsable:', c.responsible),
              ],
            ),
          ),
          Panel(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Dosis aplicadas  ${c.applied} de ${c.goal}'),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: green,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                gap,
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(20),
                  color: green,
                  backgroundColor: const Color(0xFFE7E7E7),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('0'),
                    Text('${c.goal ~/ 2}'),
                    Text('${c.goal}'),
                  ],
                ),
              ],
            ),
          ),
          if (c.status == 'Activa')
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ritmo de campaña',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  gap,
                  Text(
                    'Meta diaria: ${pace.dailyGoal} dosis · Promedio real (7 días): ${pace.dailyAverage.toStringAsFixed(1).replaceAll('.', ',')} dosis',
                  ),
                  Text(
                    pace.onTrack ? 'Al día' : 'Atrasada',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      // Rojo de advertencia (6,5:1 sobre blanco), el mismo de los lotes vencidos.
                      color: pace.onTrack ? green : const Color(0xFFB3261E),
                    ),
                  ),
                  Text(
                    pace.estimatedFinish == null || !pace.onTrack
                        ? 'No se alcanza antes del cierre'
                        : 'Meta estimada: ${shortDate(pace.estimatedFinish!)}',
                  ),
                  gap,
                  const Text('Dosis por día, últimos 14 días'),
                  _DailyBars(values: daily, goal: pace.dailyGoal),
                  const Text(
                    'Línea: meta diaria',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ActionButton(
            'Registrar vacunación',
            () => go(context, '/vaccination'),
            icon: Icons.vaccines_outlined,
          ),
          gap,
          ActionButton(
            'Editar campaña',
            () => go(context, '/campaign/edit'),
            icon: Icons.edit_outlined,
            outlined: true,
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        CircleMark(icon: icon, size: 30),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class _DailyBars extends StatelessWidget {
  const _DailyBars({required this.values, required this.goal});
  final List<int> values;
  final int goal;
  @override
  Widget build(BuildContext context) {
    final maxValue = [goal, ...values, 1].reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 110,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          return Stack(
            children: [
              Positioned.fill(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final value in values)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Container(
                            height: height * value / maxValue,
                            color: green,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: height * goal / maxValue,
                child: const Divider(color: muted, thickness: 2, height: 2),
              ),
            ],
          );
        },
      ),
    );
  }
}

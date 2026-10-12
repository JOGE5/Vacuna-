import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/page_shell.dart';

class CampaignDetailScreen extends StatelessWidget {
  const CampaignDetailScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context), c = s.selectedCampaign!;
    final progress = (c.applied / c.goal).clamp(0.0, 1.0);
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
                    Text(
                      '▦ ${dateLabel(c.start)} – ${dateLabel(c.end)}',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/images/vacuna.png',
                width: 120,
                height: 140,
                fit: BoxFit.contain,
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
          gap,
          const Center(
            child: Text(
              '◷ Última actualización: 5 oct 2026, 14:32',
              style: TextStyle(color: muted, fontSize: 11),
            ),
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/page_shell.dart';

class VaccinationHistoryScreen extends StatefulWidget {
  const VaccinationHistoryScreen({super.key});
  @override
  State<VaccinationHistoryScreen> createState() =>
      _VaccinationHistoryScreenState();
}

class _VaccinationHistoryScreenState extends State<VaccinationHistoryScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context), p = s.selectedPatient!;
    final list = s.vaccinations.where(
      (v) =>
          v.patient == p &&
          '${v.vaccine} ${v.center}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
    );
    final text =
        'VacunaPlus · ${p.name} · ${p.document}\n${list.map((v) => '${v.vaccine} · ${v.dose} · ${shortDate(v.date)} · ${v.lot} · ${v.center}').join('\n')}';
    return PageShell(
      title: 'Historial',
      back: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchBox('Buscar vacuna o centro', (v) => setState(() => query = v)),
          Panel(
            child: Row(
              children: [
                const CircleMark(icon: Icons.person_outline, size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(p.document, style: const TextStyle(color: muted)),
                    ],
                  ),
                ),
                const Icon(Icons.badge_outlined, color: green),
              ],
            ),
          ),
          const Notice('Próxima cita\n◷ 09:30  |  ⌖ Centro San Martín'),
          const Text(
            'Historial de vacunación',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          gap,
          ...list.map(
            (v) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 12, right: 10),
                  child: Icon(Icons.check_circle, color: green),
                ),
                Expanded(
                  child: Panel(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleMark(icon: Icons.vaccines_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.vaccine,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              StatusBadge(v.dose),
                              const SizedBox(height: 6),
                              Text(
                                '▦ ${shortDate(v.date)}',
                                style: const TextStyle(color: muted),
                              ),
                              Text(
                                '◇ Lote ${v.lot}',
                                style: const TextStyle(color: muted),
                              ),
                              Text(
                                '⌂ ${v.center}',
                                style: const TextStyle(color: muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (list.isEmpty)
            const Notice('No hay vacunaciones para esta búsqueda'),
          const Notice(
            'Consulta las próximas dosis según indicación del personal de salud',
          ),
          Row(
            children: [
              Expanded(
                child: ActionButton(
                  'Ver comprobante',
                  () => showDialog<void>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Comprobante'),
                      content: SingleChildScrollView(
                        child: SelectableText(text),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  ),
                  icon: Icons.description_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ActionButton(
                  'Compartir',
                  () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted)
                      toast(context, 'Comprobante copiado para compartir');
                  },
                  outlined: true,
                  icon: Icons.share_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

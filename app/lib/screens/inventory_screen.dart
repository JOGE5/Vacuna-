import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/page_shell.dart';
import '../widgets/editor_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String query = '', vaccine = 'Todas', center = 'Todos';
  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context),
        list = s.stocks.where(
          (e) =>
              '${e.vaccine} ${e.lot}'.toLowerCase().contains(
                query.toLowerCase(),
              ) &&
              (vaccine == 'Todas' || vaccine == e.vaccine) &&
              (center == 'Todos' || center == e.center),
        );
    return PageShell(
      navIndex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Brand(),
          gap,
          const Text(
            'Inventario',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          gap,
          Row(
            children: [
              _stat(
                'Dosis disponibles',
                '${s.stocks.fold<int>(0, (n, e) => n + e.quantity)}',
                Icons.medication_outlined,
              ),
              const SizedBox(width: 8),
              _stat('Existencias bajas', '3', Icons.warning_amber),
              const SizedBox(width: 8),
              _stat('Lotes por vencer', '2', Icons.calendar_month_outlined),
            ],
          ),
          SearchBox('Buscar vacuna o lote', (v) => setState(() => query = v)),
          Row(
            children: [
              Expanded(
                child: SelectField(
                  'Vacuna',
                  ['Todas', ...s.stocks.map((e) => e.vaccine).toSet()],
                  vaccine,
                  (v) => setState(() => vaccine = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SelectField(
                  'Centro',
                  ['Todos', ...s.centers.map((e) => e.name)],
                  center,
                  (v) => setState(() => center = v!),
                ),
              ),
            ],
          ),
          ...list.map(
            (e) => Panel(
              child: InkWell(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text(e.vaccine),
                    content: Text(
                      'Lote: ${e.lot}\nCentro: ${e.center}\n${e.quantity} dosis\nVence: ${shortDate(e.expiry)}',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    CircleMark(
                      icon: e.vaccine == 'SRP'
                          ? Icons.warning_amber
                          : Icons.vaccines_outlined,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.vaccine,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Lote: ${e.lot}',
                            style: const TextStyle(fontSize: 12, color: muted),
                          ),
                          Text(
                            '${e.quantity} dosis',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Vence\n${shortDate(e.expiry)}',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          ),
          if (list.isEmpty) const Notice('No hay lotes para estos filtros'),
          const Notice('Existencias bajas: SRP', warning: true),
          const Notice('Vencimiento próximo: lote SRP-2602', warning: true),
          Row(
            children: [
              Expanded(
                child: ActionButton('Registrar entrada', () async {
                  final v = await editorDialog(
                    context,
                    'Registrar entrada',
                    const ['Lote', 'Cantidad'],
                  );
                  if (v == null || !context.mounted) return;
                  final found = s.stocks.where((e) => e.lot == v['Lote']);
                  if (found.isEmpty) {
                    toast(
                      context,
                      'El lote no existe. Usa INF-2601, COV-2603 o SRP-2602.',
                    );
                    return;
                  }
                  found.first.quantity += int.parse(v['Cantidad']!);
                  s.movements.insert(
                    0,
                    'Entrada: ${v['Cantidad']} dosis · ${v['Lote']}',
                  );
                  s.changed();
                  toast(context, 'Entrada registrada');
                }, icon: Icons.add_circle_outline),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ActionButton(
                  'Movimientos',
                  () => showDialog<void>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Movimientos'),
                      content: SingleChildScrollView(
                        child: Text(
                          s.movements.isEmpty
                              ? 'Todavía no hay movimientos.'
                              : s.movements.join('\n\n'),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  ),
                  outlined: true,
                  icon: Icons.list_alt,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Expanded(
    child: Panel(
      padding: 10,
      child: Column(
        children: [
          Icon(icon, color: green),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 23,
              color: green,
            ),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/page_shell.dart';
import '../widgets/editor_dialog.dart';
import '../models/entities.dart';

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
                '${s.availableStocks.fold<int>(0, (n, e) => n + e.quantity)}',
                Icons.medication_outlined,
              ),
              const SizedBox(width: 8),
              _stat(
                'Existencias bajas',
                '${s.lowStockCount}',
                Icons.warning_amber,
              ),
              const SizedBox(width: 8),
              _stat(
                'Lotes por vencer',
                '${s.expiringStockCount}',
                Icons.calendar_month_outlined,
              ),
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
                onTap: () => _showStock(s, e),
                child: Row(
                  children: [
                    CircleMark(
                      icon: s.isExpired(e)
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
                            e.withdrawn
                                ? 'Retirado · ${e.quantity} dosis no disponibles'
                                : s.isExpired(e)
                                ? 'Vencido · ${e.quantity} dosis no disponibles'
                                : '${e.quantity} dosis',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: s.isExpired(e) || e.withdrawn
                                  ? Theme.of(context).colorScheme.error
                                  : green,
                            ),
                          ),
                          if (!e.withdrawn &&
                              !s.isExpired(e) &&
                              e.quantity > 0) ...[
                            Text(
                              s.forecast(e).days == null
                                  ? 'Sin consumo reciente'
                                  : 'Alcanza para ${s.forecast(e).days} días al ritmo actual',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (s.forecast(e).atRisk > 0)
                              Text(
                                'Se vencerían ~${s.forecast(e).atRisk} dosis: considera trasladarlas o adelantar la campaña',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      'Vence\n${shortDate(e.expiry)}',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          ),
          if (list.isEmpty) const Notice('No hay lotes para estos filtros'),
          if (s.lowStockCount > 0)
            Notice(
              'Existencias bajas: ${s.lowStockCount} lotes',
              warning: true,
            ),
          if (s.expiringStockCount > 0)
            Notice('Lotes por vencer: ${s.expiringStockCount}', warning: true),
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

  Future<void> _showStock(AppStore s, Stock stock) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text('${stock.vaccine} · ${stock.lot}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Centro: ${stock.center}\n${stock.quantity} dosis\nVence: ${shortDate(stock.expiry)}',
                ),
                if (stock.withdrawn) ...[
                  gap,
                  Text(
                    'Retirado: ${stock.withdrawalReason}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  gap,
                  const Text(
                    'Pacientes afectados',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (s.affectedBy(stock).isEmpty)
                    const Text('No hay pacientes registrados con este lote.'),
                  for (final v in s.affectedBy(stock))
                    Text(
                      '${v.patient.name} · ${v.patient.document} · ${shortDate(v.date)}',
                    ),
                ],
              ],
            ),
          ),
          actions: [
            if (!stock.withdrawn)
              TextButton(
                onPressed: () async {
                  var reason = '';
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Retirar lote'),
                      content: TextField(
                        onChanged: (value) => reason = value,
                        decoration: const InputDecoration(
                          labelText: 'Motivo del retiro',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            if (reason.trim().isEmpty) {
                              toast(c, 'Indica el motivo');
                              return;
                            }
                            Navigator.pop(c, true);
                          },
                          child: const Text('Confirmar retiro'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    s.withdrawStock(stock, reason);
                    refresh(() {});
                  }
                },
                child: const Text('Retirar lote'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        ),
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
            style: const TextStyle(fontSize: 12),
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

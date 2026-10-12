import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/page_shell.dart';

class CampaignListScreen extends StatefulWidget {
  const CampaignListScreen({super.key});
  @override
  State<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends State<CampaignListScreen> {
  String query = '', tab = 'Todas';
  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final list = s.campaigns.where(
      (c) =>
          c.name.toLowerCase().contains(query.toLowerCase()) &&
          (tab == 'Todas' ||
              c.status ==
                  {
                    'Activas': 'Activa',
                    'Próximas': 'Próxima',
                    'Finalizadas': 'Finalizada',
                  }[tab]),
    );
    return PageShell(
      navIndex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Brand(),
              const Spacer(),
              IconButton(
                onPressed: () => setState(
                  () => tab = tab == 'Activas' ? 'Todas' : 'Activas',
                ),
                icon: const Icon(Icons.filter_alt_outlined, color: green),
              ),
            ],
          ),
          const Text(
            'Campañas',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          gap,
          SearchBox('Buscar campaña', (v) => setState(() => query = v)),
          Tabs(
            const ['Todas', 'Activas', 'Próximas', 'Finalizadas'],
            tab,
            (v) => setState(() => tab = v),
          ),
          ...list.map(
            (c) => Panel(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleMark(icon: Icons.vaccines_outlined, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            StatusBadge(c.status),
                          ],
                        ),
                        gap,
                        Text(
                          '♧  ${c.vaccine}',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                        Text(
                          '▦  ${dateLabel(c.start)} – ${dateLabel(c.end)}',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                        Text(
                          '⌖  ${c.center}',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              s.selectedCampaign = c;
                              go(context, '/campaign/detail');
                            },
                            child: const Text('Ver detalle  →'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (list.isEmpty) const Notice('No se encontraron campañas'),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 190,
              child: ActionButton(
                'Crear campaña',
                () => go(context, '/campaign/new'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

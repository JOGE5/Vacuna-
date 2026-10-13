import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/theme.dart';
import '../models/entities.dart';
import '../widgets/centers_map.dart';
import '../widgets/common.dart';
import '../widgets/page_shell.dart';

/// Vista ciudadana: dónde vacunarse, campañas vigentes y cómo llegar.
/// Se entra como invitado o con Google; los datos se consultan sin internet.
class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key});
  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  String vaccine = 'Todas';
  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final available = s.stocks
        .where((e) => e.quantity > 0)
        .map((e) => e.vaccine)
        .toSet();
    final centers = s.centers
        .where(
          (c) =>
              vaccine == 'Todas' ||
              s.stocks.any(
                (e) =>
                    e.center == c.name &&
                    e.vaccine == vaccine &&
                    e.quantity > 0,
              ),
        )
        .toList();
    final campaigns =
        s.campaigns.where((e) => e.status != 'Finalizada').toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    void openCenter(String name) {
      final found = s.centers.where((c) => c.name == name);
      if (found.isNotEmpty) showCenterSheet(context, s, found.first);
    }

    return PageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Brand(),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  await s.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (r) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Salir'),
              ),
            ],
          ),
          gap,
          _hero(
            s.isGuest || !s.signedIn
                ? 'Hola, invitado'
                : 'Hola, ${s.currentUser.name.split(' ').first}',
            open: s.centers.where((c) => c.open).length,
            active: campaigns.length,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in ['Todas', ...available])
                ChoiceChip(
                  label: Text(v),
                  selected: vaccine == v,
                  onSelected: (_) => setState(() => vaccine = v),
                  selectedColor: mint,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFDDE5E1)),
                  labelStyle: TextStyle(
                    color: ink,
                    fontWeight: vaccine == v
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const SectionTitle(
            'Puntos de vacunación',
            Icons.location_on_outlined,
          ),
          CentersMap(
            centers: centers,
            height: 300,
            onSelect: (c) => showCenterSheet(context, s, c),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.location_on, color: green, size: 18),
              Text(' Abierto   ', style: TextStyle(fontSize: 12)),
              Icon(Icons.location_on, color: muted, size: 18),
              Text(' Cerrado', style: TextStyle(fontSize: 12)),
            ],
          ),
          if (centers.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Notice('No hay centros con esa vacuna disponible.'),
            ),
          const SizedBox(height: 16),
          const SectionTitle('Campañas vigentes', Icons.campaign_outlined),
          if (campaigns.isEmpty) const Notice('No hay campañas vigentes.'),
          for (final e in campaigns) _campaign(e, () => openCenter(e.center)),
          const SizedBox(height: 6),
          const SectionTitle('Centros', Icons.local_hospital_outlined),
          for (final c in centers)
            _center(c, () => showCenterSheet(context, s, c)),
          const Notice(
            'Centros y campañas se consultan sin internet. El mapa muestra las zonas que ya abriste.',
          ),
        ],
      ),
    );
  }

  Widget _hero(String greeting, {required int open, required int active}) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [green, Color(0xFF0E9F8A)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3316804A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text(
                    'Encuentra dónde vacunarte',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _pill('$open centros abiertos'),
                      _pill('$active campañas vigentes'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // La ilustración tiene fondo blanco: va en su propia tarjeta.
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/images/vacuna.png', height: 72),
              ),
            ),
          ],
        ),
      );

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0x33FFFFFF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _meta(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 13, color: muted),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text, style: const TextStyle(color: muted, fontSize: 12)),
        ),
      ],
    ),
  );

  Widget _campaign(Campaign e, VoidCallback onTap) => Panel(
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          const CircleMark(icon: Icons.vaccines_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${e.vaccine} · ${e.target}',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                _meta(
                  Icons.calendar_today_outlined,
                  '${dateLabel(e.start)} – ${dateLabel(e.end)} · ${e.center}',
                ),
              ],
            ),
          ),
          StatusBadge(e.status),
        ],
      ),
    ),
  );

  Widget _center(VaccinationCenter c, VoidCallback onTap) => Panel(
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          const CircleMark(icon: Icons.location_on_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  c.address,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                _meta(Icons.schedule, c.hours),
              ],
            ),
          ),
          StatusBadge(c.open ? 'Abierto' : 'Cerrado'),
        ],
      ),
    ),
  );
}

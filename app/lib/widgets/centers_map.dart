import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_store.dart';
import '../core/theme.dart';
import '../models/entities.dart';
import 'common.dart';
import 'page_shell.dart';

/// Mosaicos de OpenStreetMap, como en La Selva. Para otro proveedor (MapTiler,
/// OpenFreeMap…) se compila con `--dart-define=MAP_TILE_URL=<plantilla>`.
const mapTileUrl = String.fromEnvironment(
  'MAP_TILE_URL',
  defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
);

/// Identifica la app ante el servidor de mosaicos, como pide la política de OSM.
/// Debe coincidir con `applicationId` en android/app/build.gradle.kts.
const mapUserAgent = 'com.vacunaplus.app';

const laPaz = LatLng(-16.5000, -68.1193);

const _noRotation = InteractionOptions(
  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
);

/// Crea el proveedor de mosaicos. Las zonas vistas se guardan en el teléfono y
/// se consideran vigentes 30 días, así el mapa se ve sin internet (la política
/// de OSM pide guardarlas al menos 7). Las pruebas lo reemplazan.
TileProvider Function() mapTileProvider = () => NetworkTileProvider(
  cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
    overrideFreshAge: const Duration(days: 30),
  ),
);

Marker _pin(LatLng point, {required bool open, VoidCallback? onTap}) => Marker(
  point: point,
  width: 44,
  height: 44,
  alignment: Alignment.topCenter,
  child: GestureDetector(
    onTap: onTap,
    child: Icon(
      Icons.location_on,
      size: 44,
      color: open ? green : muted,
      shadows: const [Shadow(color: Color(0x55000000), blurRadius: 6)],
    ),
  ),
);

/// Crédito que exige OpenStreetMap. Pasa a dos líneas si el mapa es angosto
/// (el de flutter_map se desborda en pantallas de 320 px).
class _Attribution extends StatelessWidget {
  const _Attribution();
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomRight,
    child: GestureDetector(
      onTap: () => launchUrl(
        Uri.https('www.openstreetmap.org', '/copyright'),
        mode: LaunchMode.externalApplication,
      ).ignore(),
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xCCFFFFFF),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 10, color: ink),
        ),
      ),
    ),
  );
}

/// Mapa con un marcador por centro: verde si está abierto, gris si está cerrado.
/// Sin conexión sigue mostrando los marcadores y las zonas ya guardadas.
class CentersMap extends StatefulWidget {
  const CentersMap({
    super.key,
    required this.centers,
    required this.onSelect,
    this.height = 320,
  });
  final List<VaccinationCenter> centers;
  final ValueChanged<VaccinationCenter> onSelect;
  final double height;
  @override
  State<CentersMap> createState() => _CentersMapState();
}

class _CentersMapState extends State<CentersMap> {
  final controller = MapController();
  late final tiles = mapTileProvider();
  bool offline = false;

  List<LatLng> _points(List<VaccinationCenter> centers) => [
    for (final c in centers) LatLng(c.lat, c.lng),
  ];

  CameraFit? get _fit {
    final points = _points(widget.centers);
    return points.isEmpty
        ? null
        : CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.all(48),
            maxZoom: 15,
          );
  }

  @override
  void didUpdateWidget(CentersMap old) {
    super.didUpdateWidget(old);
    final fit = _fit;
    if (fit != null &&
        !listEquals(_points(old.centers), _points(widget.centers))) {
      // Se reencuadra en vez de recrear el mapa: TileLayer libera su proveedor.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) controller.fitCamera(fit);
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FlutterMap(
            mapController: controller,
            options: MapOptions(
              initialCenter: laPaz,
              initialZoom: 12.5,
              initialCameraFit: _fit,
              interactionOptions: _noRotation,
            ),
            children: [
              TileLayer(
                urlTemplate: mapTileUrl,
                userAgentPackageName: mapUserAgent,
                tileProvider: tiles,
                errorTileCallback: (_, _, _) {
                  if (!offline && mounted) setState(() => offline = true);
                },
              ),
              MarkerLayer(
                markers: [
                  for (final c in widget.centers)
                    _pin(
                      LatLng(c.lat, c.lng),
                      open: c.open,
                      onTap: () => widget.onSelect(c),
                    ),
                ],
              ),
              const _Attribution(),
            ],
          ),
        ),
      ),
      // Debajo del mapa: encima taparía los marcadores de la parte superior.
      if (offline)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Notice(
            'Sin conexión: se ven los centros y las zonas del mapa ya guardadas.',
            warning: true,
          ),
        ),
    ],
  );
}

/// Abre una pantalla para marcar en el mapa dónde está un centro.
Future<LatLng?> pickLocation(BuildContext context, {LatLng? initial}) =>
    Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _LocationPicker(initial),
      ),
    );

class _LocationPicker extends StatefulWidget {
  const _LocationPicker(this.initial);
  final LatLng? initial;
  @override
  State<_LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<_LocationPicker> {
  late final tiles = mapTileProvider();
  late LatLng? point = widget.initial;
  @override
  Widget build(BuildContext context) => PageShell(
    title: 'Ubicación del centro',
    back: true,
    child: Column(
      children: [
        const Notice('Toca el mapa en el lugar donde está el centro.'),
        SizedBox(
          height: 420,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point ?? laPaz,
                initialZoom: 13,
                onTap: (_, p) => setState(() => point = p),
                interactionOptions: _noRotation,
              ),
              children: [
                TileLayer(
                  urlTemplate: mapTileUrl,
                  userAgentPackageName: mapUserAgent,
                  tileProvider: tiles,
                ),
                if (point != null)
                  MarkerLayer(markers: [_pin(point!, open: true)]),
                const _Attribution(),
              ],
            ),
          ),
        ),
        gap,
        ActionButton('Guardar ubicación', () {
          if (point == null) {
            toast(context, 'Toca el mapa para elegir la ubicación');
            return;
          }
          Navigator.pop(context, point);
        }, icon: Icons.check),
      ],
    ),
  );
}

/// Ficha de un centro: estado, horario, campañas vigentes, vacunas disponibles
/// y cómo llegar.
Future<void> showCenterSheet(
  BuildContext context,
  AppStore s,
  VaccinationCenter c,
) {
  final campaigns = s.campaigns.where(
    (e) => e.center == c.name && e.status != 'Finalizada',
  );
  final vaccines = s.stocks
      .where((e) => e.center == c.name && e.quantity > 0)
      .map((e) => e.vaccine)
      .toSet();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleMark(icon: Icons.location_on_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    c.name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: ink,
                    ),
                  ),
                ),
                StatusBadge(c.open ? 'Abierto' : 'Cerrado'),
              ],
            ),
            gap,
            for (final (icon, text) in [
              (Icons.place_outlined, c.address),
              (Icons.schedule, c.hours),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: muted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(text, style: const TextStyle(color: muted)),
                    ),
                  ],
                ),
              ),
            gap,
            const Text(
              'Campañas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (campaigns.isEmpty)
              const Text(
                'Sin campañas vigentes',
                style: TextStyle(color: muted),
              ),
            for (final e in campaigns)
              Text(
                '• ${e.name} · ${e.vaccine} · ${dateLabel(e.start)} – ${dateLabel(e.end)}',
              ),
            gap,
            const Text(
              'Vacunas disponibles',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (vaccines.isEmpty)
              const Text(
                'Consulta en el centro',
                style: TextStyle(color: muted),
              ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final v in vaccines) StatusBadge(v)],
            ),
            gap,
            ActionButton(
              'Cómo llegar',
              () => openDirections(context, c),
              icon: Icons.directions_outlined,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Ruta en Google Maps hasta el centro. Los enlaces de Google Maps no
/// requieren clave de API.
Uri directionsUri(VaccinationCenter c) => Uri.https(
  'www.google.com',
  '/maps/dir/',
  {'api': '1', 'destination': '${c.lat},${c.lng}'},
);

Future<void> openDirections(BuildContext context, VaccinationCenter c) async {
  var opened = false;
  try {
    opened = await launchUrl(
      directionsUri(c),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    // Sin navegador ni app de mapas: se informa la dirección abajo.
  }
  if (!opened && context.mounted) {
    toast(context, 'No se pudo abrir Google Maps. Dirección: ${c.address}');
  }
}

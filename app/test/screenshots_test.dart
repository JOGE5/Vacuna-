import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app.dart';

void main() {
  setUpAll(() async {
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      final loader = FontLoader('VacunaSans');
      for (final f in ['Roboto-Regular.ttf']) {
        loader.addFont(
          Future.value(
            ByteData.sublistView(
              await File(
                '$root/bin/cache/artifacts/material_fonts/$f',
              ).readAsBytes(),
            ),
          ),
        );
      }
      await loader.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(
        Future.value(
          ByteData.sublistView(
            await File(
              '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
            ).readAsBytes(),
          ),
        ),
      );
      await icons.load();
    }
  });
  final routes = {
    '01_login': '/',
    '02_dashboard': '/home',
    '03_campanas': '/campaigns',
    '04_crear_campana': '/campaign/new',
    '05_detalle_campana': '/campaign/detail',
    '06_editar_campana': '/campaign/edit',
    '07_nuevo_paciente': '/patient/new',
    '08_pacientes': '/patients',
    '09_registrar_vacunacion': '/vaccination',
    '10_historial': '/history',
    '11_inventario': '/inventory',
    '12_centros': '/centers',
    '13_reportes': '/reports',
    '14_usuarios': '/users',
    '15_perfil': '/profile',
    '16_menu_mas': '/more',
  };
  for (final entry in routes.entries) {
    testWidgets('Captura ${entry.key}', (tester) async {
      tester.view.physicalSize = Size(
        540,
        {
              '/': 720.0,
              '/home': 680.0,
              '/reports': 850.0,
              '/inventory': 840.0,
              '/campaign/new': 980.0,
              '/campaign/edit': 1360.0,
              '/patient/new': 1040.0,
              '/vaccination': 1300.0,
              '/profile': 1000.0,
            }[entry.value] ??
            760.0,
      );
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: VacunaPlusApp(initialRoute: entry.value),
        ),
      );
      await tester.runAsync(() async {
        if (entry.value == '/')
          await precacheImage(
            const AssetImage('assets/images/equipo_medico.png'),
            key.currentContext!,
          );
        if (entry.value == '/campaign/detail')
          await precacheImage(
            const AssetImage('assets/images/vacuna.png'),
            key.currentContext!,
          );
      });
      await tester.pumpAndSettle();
      if (entry.value == '/') {
        await tester.tap(find.text('Ingresar'));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('../capturas/${entry.key}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
  testWidgets('Captura errores de formulario', (tester) async {
    tester.view.physicalSize = const Size(540, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: const VacunaPlusApp(initialRoute: '/patient/new'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar paciente'));
    await tester.tap(find.text('Guardar paciente'));
    await tester.pumpAndSettle();
    expect(find.text('Este campo es obligatorio'), findsWidgets);
    expect(tester.takeException(), isNull);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '../capturas/17_validaciones.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  });
}

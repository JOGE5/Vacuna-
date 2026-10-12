import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/core/app_store.dart';
import 'package:flutter_application_1/core/validators.dart';
import 'package:flutter_application_1/models/entities.dart';

void main() {
  setUpAll(() async {
    final fonts = FontLoader('VacunaSans');
    fonts.addFont(
      Future.value(
        ByteData.sublistView(
          await File('assets/fonts/Roboto-Regular.ttf').readAsBytes(),
        ),
      ),
    );
    await fonts.load();
  });

  test('Validadores: correo, contraseña, documento, teléfono y cantidades', () {
    expect(Validators.email('ana@example.com'), isNull);
    expect(Validators.email('correo malo'), isNotNull);
    expect(Validators.password('12345'), isNotNull);
    expect(Validators.password('123456'), isNull);
    expect(Validators.document('CI 1234567'), isNull);
    expect(Validators.document('1'), isNotNull);
    expect(Validators.phone('+591 712 458 90'), isNull);
    expect(Validators.phone('abc'), isNotNull);
    expect(Validators.positive('-2'), isNotNull);
    expect(Validators.positive('2.5'), isNotNull);
    expect(Validators.positive('25'), isNull);
  });
  test('Registro actualiza paciente, campaña e inventario', () {
    final s = AppStore();
    final p = Patient('Prueba', 'Paciente', 'CI 9876543', DateTime(2000));
    s.addPatient(p);
    expect(s.patients.last, p);
    final stock = s.stocks.first;
    final initial = stock.quantity;
    final campaign = s.campaigns.first;
    s.addVaccination(
      Vaccination(
        p,
        stock.vaccine,
        'Dosis 1',
        stock.lot,
        DateTime(2026, 10, 5),
        stock.center,
        'Ana Torres',
      ),
      stock,
      campaign,
    );
    expect(stock.quantity, initial - 1);
    expect(s.vaccinations.first.patient, p);
    expect(campaign.applied, 487);
    expect(s.movements, isNotEmpty);
    s.dispose();
  });
  testWidgets(
    'Login bloquea campos vacíos y permite navegación con datos válidos',
    (tester) async {
      tester.view.physicalSize = const Size(540, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const VacunaPlusApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();
      expect(find.text('Introduce un correo válido'), findsOneWidget);
      expect(find.text('Usa al menos 6 caracteres'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'ana@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();
      expect(find.text('Hola, Ana'), findsOneWidget);
      await tester.tap(find.text('Campañas'));
      await tester.pumpAndSettle();
      expect(find.text('Campaña Influenza 2026'), findsOneWidget);
      await tester.tap(find.text('Ver detalle  →').first);
      await tester.pumpAndSettle();
      expect(find.text('Editar campaña'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Búsqueda de pacientes y navegación al historial', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(540, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const VacunaPlusApp(initialRoute: '/patients'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Lucía');
    await tester.pumpAndSettle();
    expect(find.text('Juan Pablo Martínez'), findsNothing);
    await tester.tap(find.text('Ver historial'));
    await tester.pumpAndSettle();
    expect(find.text('Historial de vacunación'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Formulario de pacientes exige datos y bloquea documento duplicado',
    (tester) async {
      tester.view.physicalSize = const Size(540, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const VacunaPlusApp(initialRoute: '/patient/new'),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Guardar paciente'));
      await tester.tap(find.text('Guardar paciente'));
      await tester.pumpAndSettle();
      expect(find.text('Este campo es obligatorio'), findsWidgets);
      expect(find.text('Selecciona una fecha'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(2), 'CI 6842917');
      await tester.ensureVisible(find.text('Guardar paciente'));
      await tester.tap(find.text('Guardar paciente'));
      await tester.pumpAndSettle();
      expect(find.text('Este documento ya está registrado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Las 16 rutas se presentan en una pantalla móvil de 390 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final route in [
      '/',
      '/home',
      '/campaigns',
      '/campaign/new',
      '/campaign/detail',
      '/campaign/edit',
      '/patient/new',
      '/patients',
      '/vaccination',
      '/history',
      '/inventory',
      '/centers',
      '/reports',
      '/users',
      '/profile',
      '/more',
    ]) {
      await tester.pumpWidget(
        VacunaPlusApp(key: ValueKey(route), initialRoute: route),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: route);
    }
  });
}

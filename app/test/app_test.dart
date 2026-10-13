import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/core/app_store.dart';
import 'package:flutter_application_1/core/auth_service.dart';
import 'package:flutter_application_1/core/validators.dart';
import 'package:flutter_application_1/models/entities.dart';
import 'package:flutter_application_1/widgets/centers_map.dart';

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
  // Sin caché en disco; en pruebas los mosaicos fallan como si no hubiera internet.
  setUp(
    () => mapTileProvider = () => NetworkTileProvider(
      cachingProvider: const DisabledMapCachingProvider(),
    ),
  );
  Finder markers() => find.descendant(
    of: find.byType(MarkerLayer),
    matching: find.byIcon(Icons.location_on),
  );

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
  test(
    'Credenciales locales: acceso, rechazo, usuario inactivo y salida',
    () async {
      final s = AppStore();
      expect(s.signedIn, isFalse);
      await expectLater(
        s.signIn('ana.torres@example.com', 'incorrecta'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        s.signIn('nadie@example.com', 'salud123'),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        s.signIn('elena.vargas@example.com', 'salud123'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('inactivo'),
          ),
        ),
      );
      expect(s.signedIn, isFalse);
      await s.signIn(' Carlos.Rojas@example.com ', 'admin123');
      expect(s.signedIn, isTrue);
      expect(s.currentUser.name, 'Carlos Rojas');
      expect(s.currentUser, same(s.users[1]));
      await s.signOut();
      expect(s.signedIn, isFalse);
      s.dispose();
    },
  );
  test('La cuenta se reconoce aunque se edite su correo', () async {
    final s = AppStore();
    await s.signIn('ana.torres@example.com', 'salud123');
    s.currentUser.email = 'ana@hospital.bo';
    await s.signOut();
    await s.signIn('ana.torres@example.com', 'salud123');
    expect(s.users.length, 3);
    expect(s.currentUser, same(s.users.first));
    s.users[1]
      ..active = false
      ..email = 'carlos@hospital.bo';
    await expectLater(
      s.signIn('carlos.rojas@example.com', 'admin123'),
      throwsA(isA<AuthException>()),
    );
    s.dispose();
  });
  test('Las iniciales toleran espacios dobles', () {
    expect(
      AppUser('Luis  Paz', 'luis@example.com', 'Rol', true).initials,
      'LP',
    );
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
        'ana.torres@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'otraclave');
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();
      expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(1), 'salud123');
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
  testWidgets('Las 17 rutas se presentan en una pantalla móvil de 390 px', (
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
      '/explorar',
    ]) {
      await tester.pumpWidget(
        VacunaPlusApp(key: ValueKey(route), initialRoute: route),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: route);
    }
  });
  test('Cómo llegar abre la ruta de Google Maps hacia el centro', () {
    final c = AppStore().centers.first;
    expect(
      directionsUri(c).toString(),
      'https://www.google.com/maps/dir/?api=1&destination=-16.5095%2C-68.1255',
    );
  });
  testWidgets(
    'Invitado: mapa sin internet, filtro por vacuna y ficha del centro',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const VacunaPlusApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Entrar como invitado'));
      await tester.tap(find.text('Entrar como invitado'));
      await tester.pumpAndSettle();
      expect(find.text('Hola, invitado'), findsOneWidget);
      expect(markers(), findsNWidgets(3));
      expect(find.textContaining('Sin conexión'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'SRP'));
      await tester.pumpAndSettle();
      expect(markers(), findsOneWidget);
      await tester.tap(markers());
      await tester.pumpAndSettle();
      expect(find.text('Centro Sur'), findsWidgets);
      expect(find.text('Cómo llegar'), findsOneWidget);
      expect(find.text('Vacunas disponibles'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Google sin Supabase avisa y no inicia sesión', (tester) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = AppStore();
    await tester.pumpWidget(VacunaPlusApp(store: s));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Supabase'), findsOneWidget);
    expect(s.signedIn, isFalse);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Centros: mapa y nuevo centro con ubicación marcada', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = AppStore();
    await tester.pumpWidget(VacunaPlusApp(initialRoute: '/centers', store: s));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    expect(markers(), findsNWidgets(3));
    await tester.ensureVisible(find.text('Añadir centro').first);
    await tester.tap(find.text('Añadir centro').first);
    await tester.pumpAndSettle();
    for (final (i, text) in [
      'Centro El Alto',
      'Av. 6 de Marzo 100',
      'Lun–Vie',
    ].indexed) {
      await tester.enterText(find.byType(TextFormField).at(i), text);
    }
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Ubicación del centro'), findsOneWidget);
    await tester.tap(find.byType(FlutterMap));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(markers(), findsOneWidget);
    await tester.tap(find.text('Guardar ubicación'));
    await tester.pumpAndSettle();
    expect(find.text('Centro añadido'), findsOneWidget);
    expect(s.centers.length, 4);
    expect(s.centers.last.lat, closeTo(-16.5, 0.1));
    expect(s.centers.last.lng, closeTo(-68.12, 0.1));
    expect(tester.takeException(), isNull);
  });
}

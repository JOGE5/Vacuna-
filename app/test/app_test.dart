import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/core/app_store.dart';
import 'package:flutter_application_1/core/auth_service.dart';
import 'package:flutter_application_1/core/validators.dart';
import 'package:flutter_application_1/core/forecasts.dart';
import 'package:flutter_application_1/models/entities.dart';
import 'package:flutter_application_1/widgets/centers_map.dart';
import 'package:flutter_application_1/widgets/charts.dart';

class _MapTestTileProvider extends TileProvider {
  _MapTestTileProvider({this.fail = false});

  final bool fail;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) => fail
      ? const AssetImage('assets/images/mosaico-inexistente.png')
      : MemoryImage(TileProvider.transparentImage);
}

void main() {
  testWidgets('El botón alterna el tema y guarda la preferencia', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    await tester.pumpWidget(VacunaPlusApp(initialRoute: '/home', store: store));
    expect(find.byTooltip('Activar modo oscuro'), findsOneWidget);
    await tester.tap(find.byTooltip('Activar modo oscuro'));
    await tester.pump();
    expect(store.darkMode, isTrue);
    expect(find.byTooltip('Activar modo claro'), findsOneWidget);
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    final reopened = AppStore();
    await tester.runAsync(
      () async => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    expect(reopened.darkMode, isTrue);
    reopened.dispose();
    store.dispose();
  });
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
  test('Historial de ejemplo concilia campaña, lote y días de atención', () {
    final s = AppStore(now: () => DateTime(2026, 11, 16, 10));
    final campaign = s.campaigns.first;
    final rows = s.vaccinations.where((v) => v.campaign == campaign).toList();
    expect(rows.length, inInclusiveRange(60, 90));
    expect(campaign.applied, rows.length);
    expect(s.stocks.first.quantity, 420 - rows.length);
    expect(
      rows.every((v) => v.lot == 'INF-2601' && v.center == 'Centro San Martín'),
      isTrue,
    );
    expect(
      rows.every((v) => s.centers.first.weekdays.contains(v.date.weekday)),
      isTrue,
    );
    expect(
      rows.every(
        (v) =>
            v.date.isAfter(DateTime(2026, 10, 25)) && v.date.isBefore(s.now()),
      ),
      isTrue,
    );
    s.dispose();
  });
  test('Franjas siguen horarios, cupo y reloj inyectado', () {
    final s = AppStore(now: () => DateTime(2026, 11, 16, 8, 10));
    final center = s.centers.first;
    expect(s.bookingDays(center).length, 7);
    expect(s.bookingSlots(center, DateTime(2026, 11, 15)), isEmpty);
    expect(s.bookingSlots(center, DateTime(2026, 11, 16)).length, 18);
    expect(s.canBook(center, DateTime(2026, 11, 16, 8)), isFalse);
    final slot = DateTime(2026, 11, 16, 8, 30);
    for (var n = 0; n < 6; n++) {
      s.reserve(
        center,
        slot,
        'Persona Ejemplo',
        'CI ${9800000 + n}',
        'Influenza estacional',
      );
    }
    expect(s.slotCount(center, slot), 6);
    expect(s.canBook(center, slot), isFalse);
    expect(
      () => s.reserve(
        center,
        slot,
        'Persona Extra',
        'CI 9999999',
        'Influenza estacional',
      ),
      throwsStateError,
    );
    s.dispose();
  });
  test('El código de turno es reproducible y distingue reservas', () {
    AppStore create() => AppStore(now: () => DateTime(2026, 11, 16, 8));
    final a = create(), b = create();
    final slot = DateTime(2026, 11, 16, 9);
    final code = a
        .reserve(
          a.centers.first,
          slot,
          'Julia Paz',
          'CI 9876543',
          'Influenza estacional',
        )
        .code;
    expect(
      b
          .reserve(
            b.centers.first,
            slot,
            'Julia Paz',
            'CI 9876543',
            'Influenza estacional',
          )
          .code,
      code,
    );
    expect(
      a
          .reserve(
            a.centers.first,
            slot,
            'Mario Paz',
            'CI 9876544',
            'Influenza estacional',
          )
          .code,
      isNot(code),
    );
    expect(code, matches(RegExp(r'^VP-[0-9A-Z]{4}$')));
    a.dispose();
    b.dispose();
  });
  test('La espera estimada suma turnos pendientes y atención reciente', () {
    var clock = DateTime(2026, 11, 16, 8);
    final s = AppStore(now: () => clock);
    final center = s.centers.first;
    s.reserve(
      center,
      DateTime(2026, 11, 16, 9),
      'Julia Paz',
      'CI 9876543',
      'Influenza estacional',
    );
    clock = DateTime(2026, 11, 16, 9, 15);
    s.vaccinations.add(
      Vaccination(
        s.patients.first,
        'Influenza estacional',
        'Dosis 1',
        'INF-2601',
        DateTime(2026, 11, 16, 9, 10),
        center.name,
        'Ana',
      ),
    );
    expect(s.estimatedWait(center), 10);
    clock = DateTime(2026, 11, 16, 18);
    expect(s.estimatedWait(center), 0);
    s.dispose();
  });
  test('Ritmo calcula meta diaria y fecha con valores conocidos', () {
    final today = DateTime(2026, 11, 16);
    final campaign = Campaign(
      name: 'Prueba',
      vaccine: 'Influenza',
      center: 'Centro',
      start: today,
      end: today.add(const Duration(days: 6)),
      goal: 20,
      applied: 6,
    );
    final patient = Patient('Ana', 'Paz', 'CI 9876543', DateTime(1950));
    final rows = List.generate(
      14,
      (n) => Vaccination(
        patient,
        'Influenza',
        'Dosis 1',
        'LOTE',
        today.subtract(Duration(days: n % 7)),
        'Centro',
        'Ana',
        campaign: campaign,
      ),
    );
    final pace = campaignPace(campaign, rows, today);
    expect(pace.dailyGoal, 2);
    expect(pace.dailyAverage, 2);
    expect(pace.estimatedFinish, today.add(const Duration(days: 6)));
    expect(pace.onTrack, isTrue);
    final slow = campaignPace(campaign, rows.take(7), today);
    expect(slow.onTrack, isFalse);
    expect(slow.estimatedFinish, today.add(const Duration(days: 13)));
  });
  test('Previsión calcula duración y dosis que vencerían', () {
    final today = DateTime(2026, 11, 16);
    final stock = Stock(
      'Influenza',
      'LOTE',
      20,
      today.add(const Duration(days: 2)),
      'Centro',
    );
    final patient = Patient('Ana', 'Paz', 'CI 9876543', DateTime(1950));
    final rows = List.generate(
      7,
      (n) => Vaccination(
        patient,
        'Influenza',
        'Dosis 1',
        'LOTE',
        today.subtract(Duration(days: n)),
        'Centro',
        'Ana',
      ),
    );
    final forecast = stockForecast(stock, rows, today);
    expect(forecast.days, 20);
    expect(forecast.atRisk, 17);
    expect(stockForecast(stock, [], today).days, isNull);
  });
  test('Retirar lote bloquea disponibilidad y conserva afectados', () {
    final s = AppStore(now: () => DateTime(2026, 11, 16));
    final stock = Stock(
      'Prueba',
      'RET-01',
      10,
      DateTime(2026, 12),
      'Centro Norte',
    );
    s.stocks.add(stock);
    final patients = s.patients.take(2).toList();
    for (final p in patients) {
      s.vaccinations.add(
        Vaccination(
          p,
          'Prueba',
          'Dosis 1',
          stock.lot,
          DateTime(2026, 11, 10),
          stock.center,
          'Ana',
        ),
      );
    }
    expect(s.availableStocks, contains(stock));
    s.withdrawStock(stock, 'Control de calidad');
    expect(s.availableStocks, isNot(contains(stock)));
    expect(s.affectedBy(stock).map((v) => v.patient).toSet(), patients.toSet());
    expect(s.movements.first, contains('Retiro'));
    s.dispose();
  });
  test('Registro actualiza paciente, campaña e inventario', () {
    final s = AppStore();
    final p = Patient('Prueba', 'Paciente', 'CI 9876543', DateTime(2000));
    s.addPatient(p);
    expect(s.patients.last, p);
    final stock = s.stocks.first;
    final initial = stock.quantity;
    final campaign = s.campaigns.first;
    final initialApplied = campaign.applied;
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
    expect(campaign.applied, initialApplied + 1);
    expect(s.movements, isNotEmpty);
    s.dispose();
  });
  test('Los ejemplos siempre tienen campaña activa con lote válido', () {
    final s = AppStore();
    expect(
      s.campaigns.any(
        (campaign) =>
            campaign.status == 'Activa' &&
            s.availableStocks.any(
              (stock) =>
                  stock.vaccine == campaign.vaccine &&
                  stock.center == campaign.center,
            ),
      ),
      isTrue,
    );
    expect(s.campaigns.any((c) => c.status == 'Próxima'), isTrue);
    expect(s.campaigns.any((c) => c.status == 'Finalizada'), isTrue);
    expect(s.expiringStockCount, greaterThanOrEqualTo(1));
    expect(s.stocks.any(s.isExpired), isTrue);
    s.dispose();
  });
  test('El lote vence después de su último día de vigencia', () {
    final s = AppStore();
    final now = DateTime.now();
    final stock = s.stocks.first;
    stock.expiry = DateTime(now.year, now.month, now.day);
    expect(s.isExpired(stock), isFalse);
    expect(s.availableStocks, contains(stock));
    stock.expiry = DateTime(now.year, now.month, now.day - 1);
    expect(s.isExpired(stock), isTrue);
    expect(s.availableStocks, isNot(contains(stock)));
    s.dispose();
  });
  test('El centro abre solo dentro de sus días y horas de atención', () {
    final s = AppStore();
    final c = s.centers.first;
    expect(c.isOpenAt(DateTime(2026, 11, 16, 8)), isTrue);
    expect(c.isOpenAt(DateTime(2026, 11, 16, 7, 59)), isFalse);
    expect(c.isOpenAt(DateTime(2026, 11, 16, 17)), isFalse);
    expect(c.isOpenAt(DateTime(2026, 11, 15, 12)), isFalse);
    expect(
      c.nextOpeningAt(DateTime(2026, 11, 15, 12)),
      DateTime(2026, 11, 16, 8),
    );
    s.dispose();
  });
  test('El eje semanal usa marcas enteras distintas y decrecientes', () {
    for (var maximum = 1; maximum <= 12; maximum++) {
      final ticks = WeeklyBars.axisTicks(maximum);
      expect(ticks.last, 0, reason: 'máximo $maximum');
      expect(ticks.first, greaterThanOrEqualTo(maximum));
      expect(ticks.toSet().length, ticks.length);
      for (var index = 1; index < ticks.length; index++) {
        expect(ticks[index - 1], greaterThan(ticks[index]));
      }
      expect(ticks.length, maximum < 4 ? maximum + 1 : 5);
    }
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
      await tester.tap(find.text('Ver detalle').first);
      await tester.pumpAndSettle();
      expect(find.text('Editar campaña'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Registro por interfaz actualiza campaña e inventario', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(540, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = AppStore();
    addTearDown(s.dispose);
    final initialVaccinations = s.vaccinations.length;
    final stock = s.stocks.firstWhere((e) => e.lot == 'INF-2601');
    final initialQuantity = stock.quantity;
    final campaign = s.campaigns.firstWhere(
      (e) => e.name == 'Campaña Influenza 2026',
    );
    final initialApplied = campaign.applied;
    await tester.pumpWidget(VacunaPlusApp(store: s));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'ana.torres@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'salud123');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();
    expect(s.currentUser.name, 'Ana Torres');
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed('/vaccination');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Campaña Influenza 2026').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dosis 1').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('INF-2601').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar vacunación'));
    await tester.tap(find.text('Guardar vacunación'));
    await tester.pumpAndSettle();
    expect(s.vaccinations.length, initialVaccinations + 1);
    expect(stock.quantity, initialQuantity - 1);
    expect(campaign.applied, initialApplied + 1);
    expect(s.vaccinations.first.responsible, 'Ana Torres');
    expect(s.vaccinations.first.campaign, same(campaign));
    expect(s.vaccinations.first.lot, 'INF-2601');
    expect(s.vaccinations.first.dose, 'Dosis 1');
    expect(tester.takeException(), isNull);
  });
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
  testWidgets('Las 18 rutas se presentan en una pantalla móvil de 390 px', (
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
      '/turnos',
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
      expect(find.widgetWithText(ChoiceChip, 'SRP'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Influenza estacional'));
      await tester.pumpAndSettle();
      expect(markers(), findsOneWidget);
      expect(find.text('Refuerzo infantil'), findsNothing);
      await tester.tap(markers());
      await tester.pumpAndSettle();
      expect(find.text('Centro San Martín'), findsWidgets);
      expect(find.text('Cómo llegar'), findsOneWidget);
      expect(find.text('Llamar'), findsOneWidget);
      expect(find.text('Vacunas disponibles'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.textContaining('Personas mayores de 60 años'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('La ficha de Centro Sur no ofrece el lote SRP vencido', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = AppStore();
    addTearDown(s.dispose);
    await tester.pumpWidget(VacunaPlusApp(initialRoute: '/explorar', store: s));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'SRP'), findsNothing);
    await tester.tap(markers().last);
    await tester.pumpAndSettle();
    expect(find.text('Centro Sur'), findsWidgets);
    expect(find.text('Vacunas disponibles'), findsOneWidget);
    expect(find.text('Consulta en el centro'), findsOneWidget);
    expect(find.text('SRP'), findsNothing);
  });
  testWidgets(
    'El mapa ciudadano deja desplazar la página y abre el mapa completo',
    (tester) async {
      mapTileProvider = _MapTestTileProvider.new;
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const VacunaPlusApp(initialRoute: '/explorar'));
      await tester.pumpAndSettle();
      expect(
        find.byType(CentersMap).first.evaluate().single.widget,
        isA<CentersMap>().having((m) => m.interactive, 'interactive', isFalse),
      );
      expect(
        tester
            .widget<FlutterMap>(find.byType(FlutterMap).first)
            .options
            .interactionOptions
            .flags,
        InteractiveFlag.none,
      );
      final scroll = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      final before = scroll.pixels;
      await tester.drag(find.byType(FlutterMap).first, const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(scroll.pixels, greaterThan(before));
      await tester.ensureVisible(find.text('Ver mapa completo'));
      await tester.tap(find.text('Ver mapa completo'));
      await tester.pumpAndSettle();
      expect(find.text('Mapa completo'), findsOneWidget);
      expect(
        tester.widget<CentersMap>(find.byType(CentersMap)).interactive,
        isTrue,
      );
      expect(
        tester
                .widget<FlutterMap>(find.byType(FlutterMap))
                .options
                .interactionOptions
                .flags &
            InteractiveFlag.rotate,
        0,
      );
      expect(markers(), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Mapa completo sin conexión no se desborda con letra ampliada', (
    tester,
  ) async {
    mapTileProvider = () => _MapTestTileProvider(fail: true);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const VacunaPlusApp(initialRoute: '/explorar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ver mapa completo'));
    await tester.tap(find.text('Ver mapa completo'));
    await tester.pumpAndSettle();
    expect(find.text('Mapa completo'), findsOneWidget);
    expect(find.textContaining('Sin conexión'), findsOneWidget);
    expect(
      MediaQuery.textScalerOf(
        tester.element(find.text('Mapa completo')),
      ).scale(10),
      13,
    );
    expect(tester.takeException(), isNull);
  });
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
      '+591 2 2000004',
    ].indexed) {
      await tester.enterText(find.byType(TextFormField).at(i), text);
    }
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Horario de atención'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Sáb'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
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
    expect(s.centers.last.weekdays, {1, 2, 3, 4, 5, 6});
    expect(s.centers.last.hours, 'Lun–Sáb · 08:00–17:00');
    expect(s.centers.last.phone, '+591 2 2000004');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Invitado reserva y personal ve el turno en la misma pestaña', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = AppStore(now: () => DateTime(2026, 11, 16, 9));
    addTearDown(s.dispose);
    await tester.pumpWidget(VacunaPlusApp(store: s));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Entrar como invitado'));
    await tester.tap(find.text('Entrar como invitado'));
    await tester.pumpAndSettle();
    await tester.tap(markers().first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reservar turno'));
    await tester.tap(find.text('Reservar turno'));
    await tester.pumpAndSettle();
    expect(find.text('Reservar turno'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '16/11'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '09:30'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Julia Paz');
    await tester.enterText(find.byType(TextFormField).at(1), 'CI 9876543');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Influenza estacional').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirmar turno'));
    await tester.tap(find.text('Confirmar turno'));
    await tester.pumpAndSettle();
    expect(s.appointments.length, 1);
    expect(find.textContaining(s.appointments.single.code), findsWidgets);
    // La app usa su propio botón de volver (IconButton con tooltip), no BackButton.
    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'ana.torres@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'salud123');
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Turnos de hoy: 1'));
    await tester.pumpAndSettle();
    expect(find.text('Julia Paz'), findsOneWidget);
    expect(find.textContaining(s.appointments.single.code), findsOneWidget);
    expect(find.text('Atender'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

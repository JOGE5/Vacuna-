import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/entities.dart';
import 'auth_service.dart';
import 'forecasts.dart';
import 'validators.dart';

class AppStore extends ChangeNotifier {
  final AuthService auth;
  final DateTime Function() now;
  late final DateTime _sampleDay = _dateOnly(now());
  DateTime _sampleDate(int offset) =>
      DateTime(_sampleDay.year, _sampleDay.month, _sampleDay.day + offset);

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  late final campaigns = <Campaign>[
    Campaign(
      name: 'Campaña Influenza 2026',
      vaccine: 'Influenza estacional',
      center: 'Centro San Martín',
      start: _sampleDate(-21),
      end: _sampleDate(20),
      description: 'Protección para personas mayores durante la temporada 2026',
    ),
    Campaign(
      name: 'Refuerzo infantil',
      vaccine: 'SRP',
      center: 'Centro Norte',
      start: _sampleDate(15),
      end: _sampleDate(35),
      target: 'Niñas y niños de 1 a 5 años',
      goal: 320,
      applied: 0,
    ),
    Campaign(
      name: 'Semana de la Hepatitis',
      vaccine: 'Hepatitis B',
      center: 'Centro Sur',
      start: _sampleDate(-75),
      end: _sampleDate(-69),
    ),
  ];
  final patients = <Patient>[
    Patient(
      'Lucía',
      'Mendoza Rojas',
      'CI 6842917',
      DateTime(1998, 3, 12),
      phone: '+591 712 458 90',
      address: 'Av. Los Pinos 245, La Paz',
      emergency: 'Carlos Mendoza · +591 765 230 11',
    ),
    Patient(
      'Juan Pablo',
      'Martínez',
      'CI 7538204',
      DateTime(1990, 6, 3),
      sex: 'Masculino',
    ),
    Patient('Ana Sofía', 'Álvarez', 'CI 8125590', DateTime(2000, 2, 5)),
  ];
  late final stocks = <Stock>[
    Stock(
      'Influenza estacional',
      'INF-2601',
      420,
      _sampleDate(60),
      'Centro San Martín',
    ),
    Stock('COVID-19', 'COV-2603', 680, _sampleDate(20), 'Centro Norte'),
    Stock('SRP', 'SRP-2602', 148, _sampleDate(-19), 'Centro Sur'),
  ];
  final centers = <VaccinationCenter>[
    VaccinationCenter(
      'Centro San Martín',
      'Av. Arce 1250, La Paz',
      'Lun–Vie · 08:00–17:00',
      weekdays: {1, 2, 3, 4, 5},
      opensAt: 8 * 60,
      closesAt: 17 * 60,
      phone: '+591 2 2000001',
      lat: -16.5095,
      lng: -68.1255,
    ),
    VaccinationCenter(
      'Centro Norte',
      'Av. Busch 740, La Paz',
      'Lun–Sáb · 09:00–16:00',
      weekdays: {1, 2, 3, 4, 5, 6},
      opensAt: 9 * 60,
      closesAt: 16 * 60,
      phone: '+591 2 2000002',
      lat: -16.4960,
      lng: -68.1195,
    ),
    VaccinationCenter(
      'Centro Sur',
      'Calle 21 de Calacoto 88, La Paz',
      'Lun–Vie · 08:00–15:00',
      weekdays: {1, 2, 3, 4, 5},
      opensAt: 8 * 60,
      closesAt: 15 * 60,
      phone: '+591 2 2000003',
      lat: -16.5415,
      lng: -68.0775,
    ),
  ];
  final users = <AppUser>[
    AppUser(
      'Ana Torres',
      'ana.torres@example.com',
      'Personal de salud',
      true,
      id: 'ana-torres',
    ),
    AppUser(
      'Carlos Rojas',
      'carlos.rojas@example.com',
      'Administrador',
      true,
      id: 'carlos-rojas',
    ),
    AppUser(
      'Elena Vargas',
      'elena.vargas@example.com',
      'Personal de salud',
      false,
      id: 'elena-vargas',
    ),
  ];
  final vaccinations = <Vaccination>[];
  final appointments = <Appointment>[];
  final movements = <String>[];
  Patient? selectedPatient;
  Campaign? selectedCampaign;
  Appointment? selectedAppointment;
  bool notifications = true;
  bool darkMode = false;
  bool _themeTouched = false;
  bool _disposed = false;
  Future<void> _loadDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool('dark_mode') ?? false;
      if (!_disposed && !_themeTouched && darkMode != saved) {
        darkMode = saved;
        notifyListeners();
      }
    } catch (_) {
      // Si no hay almacenamiento, el control sigue funcionando en la sesión.
    }
  }

  void toggleDarkMode() {
    darkMode = !darkMode;
    _themeTouched = true;
    notifyListeners();
    final selected = darkMode;
    SharedPreferences.getInstance()
        .then((prefs) => prefs.setBool('dark_mode', selected))
        .catchError((Object _) => false);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  AppUser? _session;
  AppStore({this.auth = const LocalAuthService(), DateTime Function()? now})
    : now = now ?? DateTime.now {
    _loadDarkMode();
    selectedPatient = patients.first;
    selectedCampaign = campaigns.first;
    vaccinations.addAll([
      Vaccination(
        patients.first,
        'Influenza estacional',
        'Dosis 1',
        'INF-2501',
        DateTime(2026, 4, 15),
        'Centro San Martín',
        'Ana Torres',
      ),
      Vaccination(
        patients.first,
        'COVID-19',
        'Dosis de refuerzo',
        'COV-2511',
        DateTime(2025, 11, 8),
        'Centro Norte',
        'Ana Torres',
      ),
    ]);
    // 77 dosis en los 15 días laborables de las últimas tres semanas.
    const firstNames = [
      'María',
      'Pedro',
      'Elena',
      'Luis',
      'Rosa',
      'Miguel',
      'Carmen',
      'Jorge',
      'Sofía',
      'Raúl',
    ];
    const lastNames = [
      'Quispe',
      'Flores',
      'Mamani',
      'Vargas',
      'Choque',
      'Paredes',
      'Ríos',
      'Salazar',
    ];
    final campaign = campaigns.first;
    var index = 0;
    var workingDay = 0;
    for (var daysAgo = 21; daysAgo >= 1; daysAgo--) {
      if (!centers.first.weekdays.contains(_sampleDate(-daysAgo).weekday))
        continue;
      final count = [4, 6, 5, 7, 3, 5, 4, 6, 7, 4, 5, 6, 3, 7, 5][workingDay++];
      for (var n = 0; n < count; n++) {
        final p = Patient(
          firstNames[index % firstNames.length],
          lastNames[index % lastNames.length],
          'CI ${9000000 + index}',
          DateTime(1945 + index % 20, index % 12 + 1, index % 27 + 1),
        );
        patients.add(p);
        vaccinations.insert(
          0,
          Vaccination(
            p,
            campaign.vaccine,
            'Dosis 1',
            'INF-2601',
            _sampleDate(
              -daysAgo,
            ).add(Duration(hours: 8 + n, minutes: index % 2 * 15)),
            campaign.center,
            'Ana Torres',
            campaign: campaign,
          ),
        );
        index++;
      }
    }
    campaign.applied = index;
    stocks.first.quantity = 420 - index;
  }
  // Roles de la vista ciudadana; los demás son del personal de salud.
  static const citizenRole = 'Ciudadano', guestRole = 'Invitado';
  bool get signedIn => _session != null;
  bool get isGuest => _session?.role == guestRole;
  // Sin sesión (rutas abiertas directamente en pruebas) se muestra el primer usuario.
  AppUser get currentUser => _session ?? users.first;
  bool get isAdmin => currentUser.role == 'Administrador';
  bool isExpired(Stock stock) =>
      _dateOnly(stock.expiry).isBefore(_dateOnly(now()));

  Iterable<Stock> get availableStocks =>
      stocks.where((e) => e.quantity > 0 && !e.withdrawn && !isExpired(e));

  int get lowStockCount => availableStocks.where((e) => e.quantity < 50).length;
  int get expiringStockCount => stocks
      .where((e) => e.quantity > 0 && !e.withdrawn && !isExpired(e))
      .where(
        (e) => _dateOnly(e.expiry).difference(_dateOnly(now())).inDays < 30,
      )
      .length;

  Future<void> signIn(String email, String password) async {
    final user = await auth.signIn(email, password);
    // La cuenta se reconoce por su id, que no cambia si se edita el correo.
    final existing = users.where(
      (u) => user.id.isNotEmpty
          ? u.id == user.id
          : u.email.toLowerCase() == user.email.toLowerCase(),
    );
    if (existing.isNotEmpty && !existing.first.active) {
      await auth.signOut();
      throw const AuthException(
        'Tu usuario está inactivo. Contacta a un administrador.',
      );
    }
    if (existing.isEmpty) users.add(user);
    _session = existing.isEmpty ? user : existing.first;
    notifyListeners();
  }

  void enterAsGuest() {
    _session = AppUser('Invitado', '', guestRole, true);
    notifyListeners();
  }

  // Los ciudadanos no se agregan a la lista de usuarios del personal.
  Future<void> signInWithGoogle() async {
    final user = await auth.signInWithGoogle();
    _session = user..role = citizenRole;
    notifyListeners();
  }

  Future<void> signOut() async {
    await auth.signOut();
    _session = null;
    notifyListeners();
  }

  void changed() => notifyListeners();
  void addPatient(Patient p) {
    patients.add(p);
    selectedPatient = p;
    notifyListeners();
  }

  void saveCampaign(Campaign c, Campaign? original) {
    if (original == null) {
      campaigns.add(c);
    } else {
      campaigns[campaigns.indexOf(original)] = c;
    }
    selectedCampaign = c;
    notifyListeners();
  }

  void addVaccination(Vaccination v, Stock stock, Campaign? c) {
    if (stock.withdrawn || isExpired(stock) || stock.quantity <= 0) {
      throw StateError('El lote no está disponible');
    }
    vaccinations.insert(0, v);
    stock.quantity--;
    c?.applied++;
    if (selectedAppointment != null &&
        selectedAppointment!.document.toLowerCase() ==
            v.patient.document.toLowerCase() &&
        selectedAppointment!.vaccine == v.vaccine &&
        selectedAppointment!.center == v.center) {
      selectedAppointment!.attended = true;
      selectedAppointment = null;
    }
    movements.insert(0, 'Salida: 1 dosis ${stock.vaccine} · ${v.patient.name}');
    notifyListeners();
  }

  Iterable<DateTime> bookingDays(VaccinationCenter center) sync* {
    final today = _dateOnly(now());
    var offered = 0;
    for (var n = 0; n < 56 && offered < 7; n++) {
      final day = today.add(Duration(days: n));
      if (center.weekdays.contains(day.weekday) &&
          bookingSlots(center, day).any((slot) => slot.isAfter(now()))) {
        yield day;
        offered++;
      }
    }
  }

  Iterable<DateTime> bookingSlots(
    VaccinationCenter center,
    DateTime day,
  ) sync* {
    if (!center.weekdays.contains(day.weekday)) return;
    final start = _dateOnly(day);
    for (
      var minute = center.opensAt;
      minute + 30 <= center.closesAt;
      minute += 30
    ) {
      yield start.add(Duration(minutes: minute));
    }
  }

  int slotCount(VaccinationCenter center, DateTime slot) => appointments
      .where((a) => a.center == center.name && a.slot == slot)
      .length;

  bool canBook(VaccinationCenter center, DateTime slot) =>
      bookingDays(center).any((day) => day == _dateOnly(slot)) &&
      bookingSlots(center, slot).contains(slot) &&
      slot.isAfter(now()) &&
      slotCount(center, slot) < 6 &&
      availableStocks.any((stock) => stock.center == center.name);

  Appointment reserve(
    VaccinationCenter center,
    DateTime slot,
    String name,
    String document,
    String vaccine,
  ) {
    if (name.trim().split(RegExp(r'\s+')).length < 2 ||
        Validators.document(document) != null) {
      throw ArgumentError('Nombre o CI inválido');
    }
    if (!canBook(center, slot) ||
        !availableStocks.any(
          (s) => s.center == center.name && s.vaccine == vaccine,
        )) {
      throw StateError('La franja o vacuna ya no está disponible');
    }
    final data =
        '${center.name}|${slot.toIso8601String()}|${name.trim()}|${document.trim()}|$vaccine|${slotCount(center, slot)}';
    var hash = 2166136261;
    for (final unit in data.codeUnits) {
      hash = ((hash ^ unit) * 16777619) & 0xffffffff;
    }
    var code =
        'VP-${(hash % 1679616).toRadixString(36).toUpperCase().padLeft(4, '0')}';
    while (appointments.any((a) => a.code == code)) {
      hash = ((hash ^ appointments.length) * 16777619) & 0xffffffff;
      code =
          'VP-${(hash % 1679616).toRadixString(36).toUpperCase().padLeft(4, '0')}';
    }
    final appointment = Appointment(
      code,
      center.name,
      slot,
      name.trim(),
      document.trim(),
      vaccine,
    );
    appointments.add(appointment);
    notifyListeners();
    return appointment;
  }

  int estimatedWait(VaccinationCenter center) {
    final time = now();
    if (!center.isOpenAt(time)) return 0;
    final minutes = time.hour * 60 + time.minute;
    final slot = _dateOnly(time).add(
      Duration(
        minutes: center.opensAt + ((minutes - center.opensAt) ~/ 30) * 30,
      ),
    );
    final pending = appointments
        .where((a) => a.center == center.name && a.slot == slot && !a.attended)
        .length;
    final walkIns = vaccinations
        .where(
          (v) =>
              v.center == center.name &&
              v.date.isAfter(time.subtract(const Duration(hours: 1))) &&
              !v.date.isAfter(time) &&
              !appointments.any(
                (a) =>
                    a.attended &&
                    a.center == center.name &&
                    a.document == v.patient.document &&
                    a.slot.isAfter(time.subtract(const Duration(hours: 2))),
              ),
        )
        .length;
    return (pending + walkIns) * 5;
  }

  Iterable<Appointment> get todayAppointments =>
      appointments.where((a) => _dateOnly(a.slot) == _dateOnly(now()));

  Patient prepareAppointment(Appointment appointment) {
    final existing = patients.where(
      (p) => p.document.toLowerCase() == appointment.document.toLowerCase(),
    );
    final patient = existing.isNotEmpty
        ? existing.first
        : Patient(
            appointment.name.split(' ').first,
            appointment.name.split(' ').skip(1).join(' ').isEmpty
                ? 'Sin apellido'
                : appointment.name.split(' ').skip(1).join(' '),
            appointment.document,
            null,
          );
    if (existing.isEmpty) patients.add(patient);
    selectedPatient = patient;
    selectedAppointment = appointment;
    notifyListeners();
    return patient;
  }

  void cancelAppointmentPreparation(Appointment? appointment) {
    if (selectedAppointment == appointment) selectedAppointment = null;
  }

  List<Vaccination> affectedBy(Stock stock) => vaccinations
      .where((v) => v.lot == stock.lot && v.center == stock.center)
      .toList();

  void withdrawStock(Stock stock, String reason) {
    if (reason.trim().isEmpty) throw ArgumentError('Indica el motivo');
    stock.withdrawn = true;
    stock.withdrawalReason = reason.trim();
    movements.insert(0, 'Retiro: ${stock.lot} · ${stock.withdrawalReason}');
    notifyListeners();
  }

  CampaignPace pace(Campaign campaign) =>
      campaignPace(campaign, vaccinations, now());
  StockForecast forecast(Stock stock) =>
      stockForecast(stock, vaccinations, now());
}

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
    : super(notifier: store);
  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

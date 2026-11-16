class Campaign {
  Campaign({
    required this.name,
    required this.vaccine,
    required this.center,
    required this.start,
    required this.end,
    this.description = '',
    this.target = 'Personas mayores de 60 años',
    this.responsible = 'Ana Torres',
    this.goal = 800,
    this.applied = 0,
  });
  String name, vaccine, center, description, target, responsible;
  DateTime start, end;
  int goal, applied;
  String get status {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    if (day.isBefore(DateTime(start.year, start.month, start.day)))
      return 'Próxima';
    if (day.isAfter(DateTime(end.year, end.month, end.day)))
      return 'Finalizada';
    return 'Activa';
  }
}

class Patient {
  Patient(
    this.first,
    this.last,
    this.document,
    this.birth, {
    this.sex = 'Femenino',
    this.phone = '',
    this.address = '',
    this.emergency = '',
  });
  String first, last, document, sex, phone, address, emergency;
  DateTime? birth;
  String get name => '$first $last';
  String get initials => '${first[0]}${last[0]}';
}

class Vaccination {
  Vaccination(
    this.patient,
    this.vaccine,
    this.dose,
    this.lot,
    this.date,
    this.center,
    this.responsible, {
    this.next,
    this.notes = '',
    this.campaign,
  });
  Patient patient;
  String vaccine, dose, lot, center, responsible, notes;
  DateTime date;
  DateTime? next;
  Campaign? campaign;
}

class Stock {
  Stock(this.vaccine, this.lot, this.quantity, this.expiry, this.center);
  String vaccine, lot, center;
  int quantity;
  DateTime expiry;
  bool withdrawn = false;
  String withdrawalReason = '';
}

class Appointment {
  Appointment(
    this.code,
    this.center,
    this.slot,
    this.name,
    this.document,
    this.vaccine,
  );
  final String code, center, name, document, vaccine;
  final DateTime slot;
  bool attended = false;

  String get summary =>
      'Turno $code\n$name · $document\n$vaccine\n$center\n'
      '${slot.day.toString().padLeft(2, '0')}/${slot.month.toString().padLeft(2, '0')}/${slot.year} '
      '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}';
}

class VaccinationCenter {
  VaccinationCenter(
    this.name,
    this.address,
    this.hours, {
    required this.weekdays,
    required this.opensAt,
    required this.closesAt,
    required this.phone,
    required this.lat,
    required this.lng,
  }) : assert(opensAt >= 0 && opensAt < closesAt && closesAt <= 1440);
  String name, address, hours, phone;
  Set<int> weekdays;

  /// Minutos desde medianoche, según la hora local del centro.
  int opensAt, closesAt;
  double lat, lng;

  bool isOpenAt(DateTime time) =>
      weekdays.contains(time.weekday) &&
      time.hour * 60 + time.minute >= opensAt &&
      time.hour * 60 + time.minute < closesAt;

  DateTime? nextOpeningAt(DateTime time) {
    if (weekdays.isEmpty) return null;
    for (var days = 0; days <= 7; days++) {
      final day = DateTime(time.year, time.month, time.day + days);
      if (!weekdays.contains(day.weekday)) continue;
      final opening = day.add(Duration(minutes: opensAt));
      if (opening.isAfter(time)) return opening;
    }
    return null;
  }
}

class AppUser {
  AppUser(this.name, this.email, this.role, this.active, {this.id = ''});
  // Identificador de la cuenta de acceso; vacío si el usuario no tiene credenciales.
  final String id;
  String name, email, role;
  bool active;
  String get initials => name
      .split(' ')
      .where((e) => e.isNotEmpty)
      .map((e) => e[0])
      .take(2)
      .join();
}

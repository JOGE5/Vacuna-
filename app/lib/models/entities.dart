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
    this.status = 'Activa',
    this.goal = 800,
    this.applied = 486,
  });
  String name, vaccine, center, description, target, responsible, status;
  DateTime start, end;
  int goal, applied;
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
  DateTime birth;
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
  });
  Patient patient;
  String vaccine, dose, lot, center, responsible, notes;
  DateTime date;
  DateTime? next;
}

class Stock {
  Stock(this.vaccine, this.lot, this.quantity, this.expiry, this.center);
  String vaccine, lot, center;
  int quantity;
  DateTime expiry;
}

class VaccinationCenter {
  VaccinationCenter(
    this.name,
    this.address,
    this.hours,
    this.open, {
    required this.lat,
    required this.lng,
  });
  String name, address, hours;
  bool open;
  double lat, lng;
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

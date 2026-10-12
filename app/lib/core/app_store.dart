import 'package:flutter/material.dart';
import '../models/entities.dart';

class AppStore extends ChangeNotifier {
  final campaigns = <Campaign>[
    Campaign(
      name: 'Campaña Influenza 2026',
      vaccine: 'Influenza tetravalente',
      center: 'Centro San Martín',
      start: DateTime(2026, 10, 6),
      end: DateTime(2026, 10, 30),
      description: 'Protección para personas mayores durante la temporada 2026',
    ),
    Campaign(
      name: 'Refuerzo infantil',
      vaccine: 'SRP',
      center: 'Centro Norte',
      start: DateTime(2026, 10, 18),
      end: DateTime(2026, 10, 25),
      status: 'Próxima',
      target: 'Niñas y niños de 1 a 5 años',
      goal: 320,
      applied: 0,
    ),
    Campaign(
      name: 'Semana de la Hepatitis',
      vaccine: 'Hepatitis B',
      center: 'Centro Sur',
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 9, 7),
      status: 'Finalizada',
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
  final stocks = <Stock>[
    Stock(
      'Influenza estacional',
      'INF-2601',
      420,
      DateTime(2026, 11, 30),
      'Centro San Martín',
    ),
    Stock('COVID-19', 'COV-2603', 680, DateTime(2026, 12, 15), 'Centro Norte'),
    Stock('SRP', 'SRP-2602', 148, DateTime(2026, 10, 28), 'Centro Sur'),
  ];
  final centers = <VaccinationCenter>[
    VaccinationCenter(
      'Centro San Martín',
      'Av. Arce 1250, La Paz',
      'Lun–Vie · 08:00–17:00',
      true,
    ),
    VaccinationCenter(
      'Centro Norte',
      'Av. Busch 740, La Paz',
      'Lun–Sáb · 09:00–16:00',
      true,
    ),
    VaccinationCenter(
      'Centro Sur',
      'Calle 21 de Calacoto 88, La Paz',
      'Lun–Vie · 08:00–15:00',
      false,
    ),
  ];
  final users = <AppUser>[
    AppUser('Ana Torres', 'ana.torres@example.com', 'Personal de salud', true),
    AppUser('Carlos Rojas', 'carlos.rojas@example.com', 'Administrador', true),
    AppUser(
      'Elena Vargas',
      'elena.vargas@example.com',
      'Personal de salud',
      false,
    ),
  ];
  final vaccinations = <Vaccination>[];
  final movements = <String>[];
  Patient? selectedPatient;
  Campaign? selectedCampaign;
  bool notifications = true;
  AppStore() {
    selectedPatient = patients.first;
    selectedCampaign = campaigns.first;
    vaccinations.addAll([
      Vaccination(
        patients.first,
        'Influenza estacional',
        'Dosis 1',
        'INF-2601',
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

  void addVaccination(Vaccination v, Stock stock, Campaign c) {
    vaccinations.insert(0, v);
    stock.quantity--;
    c.applied++;
    movements.insert(0, 'Salida: 1 dosis ${stock.vaccine} · ${v.patient.name}');
    notifyListeners();
  }
}

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
    : super(notifier: store);
  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

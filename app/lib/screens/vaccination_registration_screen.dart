import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../models/entities.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/page_shell.dart';

class VaccinationRegistrationScreen extends StatefulWidget {
  const VaccinationRegistrationScreen({super.key});
  @override
  State<VaccinationRegistrationScreen> createState() =>
      _VaccinationRegistrationScreenState();
}

class _VaccinationRegistrationScreenState
    extends State<VaccinationRegistrationScreen> {
  final form = GlobalKey<FormState>();
  final lot = TextEditingController(), notes = TextEditingController();
  String? campaign, vaccine, dose, center, responsible;
  DateTime? date, next;
  String query = '';
  @override
  void dispose() {
    lot.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context), p = s.selectedPatient;
    final matches = s.patients.where(
      (p) =>
          '${p.name} ${p.document}'.toLowerCase().contains(query.toLowerCase()),
    );
    return PageShell(
      title: 'Registrar vacunación',
      back: true,
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Completa los datos para registrar la aplicación.',
              style: TextStyle(fontSize: 12),
            ),
            gap,
            SearchBox(
              'Buscar por documento (CI, pasaporte, etc.)',
              (v) => setState(() => query = v),
            ),
            if (query.isNotEmpty)
              Panel(
                child: Column(
                  children: matches
                      .map(
                        (p) => ListTile(
                          title: Text(p.name),
                          subtitle: Text(p.document),
                          onTap: () => setState(() {
                            s.selectedPatient = p;
                            query = '';
                          }),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (p != null)
              Panel(
                child: Row(
                  children: [
                    const CircleMark(icon: Icons.person_outline, size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(p.document),
                          Text(
                            'Nacida el ${shortDate(p.birth)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Panel(
              child: Column(
                children: [
                  const SectionTitle(
                    'Vacuna y dosis',
                    Icons.health_and_safety_outlined,
                  ),
                  SelectField(
                    'Campaña',
                    s.campaigns.map((c) => c.name).toList(),
                    campaign,
                    (v) => setState(() => campaign = v),
                  ),
                  SelectField(
                    'Vacuna',
                    s.stocks.map((e) => e.vaccine).toSet().toList(),
                    vaccine,
                    (v) => setState(() => vaccine = v),
                  ),
                  SelectField(
                    'Dosis',
                    const ['Dosis 1', 'Dosis 2', 'Dosis de refuerzo'],
                    dose,
                    (v) => setState(() => dose = v),
                  ),
                  InputField(
                    'Lote',
                    lot,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Este campo es obligatorio';
                      final candidates = s.stocks.where(
                        (e) =>
                            e.lot == v.trim() &&
                            e.vaccine == vaccine &&
                            e.center == center,
                      );
                      if (candidates.isEmpty)
                        return 'Lote no disponible para esta vacuna y centro';
                      final stock = candidates.first;
                      if (stock.quantity <= 0)
                        return 'No hay dosis disponibles';
                      if (date != null && stock.expiry.isBefore(date!))
                        return 'El lote está vencido en la fecha indicada';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            Panel(
              child: Column(
                children: [
                  const SectionTitle(
                    'Datos de aplicación',
                    Icons.calendar_today_outlined,
                  ),
                  DateField(
                    'Fecha de aplicación',
                    date,
                    (v) => setState(() => date = v),
                    last: DateTime.now(),
                  ),
                  SelectField(
                    'Centro',
                    s.centers.map((e) => e.name).toList(),
                    center,
                    (v) => setState(() => center = v),
                  ),
                  SelectField(
                    'Responsable',
                    s.users.where((u) => u.active).map((e) => e.name).toList(),
                    responsible,
                    (v) => setState(() => responsible = v),
                  ),
                  InputField('Observaciones', notes, lines: 2, validator: null),
                  DateField(
                    'Próxima cita (opcional)',
                    next,
                    (v) => setState(() => next = v),
                    validator: (_) =>
                        next != null && date != null && !next!.isAfter(date!)
                        ? 'La cita debe ser posterior a la aplicación'
                        : null,
                  ),
                ],
              ),
            ),
            ActionButton('Guardar vacunación', () {
              if (!form.currentState!.validate()) return;
              if (p == null) {
                toast(context, 'Selecciona un paciente');
                return;
              }
              final c = s.campaigns.firstWhere((c) => c.name == campaign);
              final stock = s.stocks.firstWhere(
                (e) =>
                    e.lot == lot.text.trim() &&
                    e.vaccine == vaccine &&
                    e.center == center,
              );
              s.addVaccination(
                Vaccination(
                  p,
                  vaccine!,
                  dose!,
                  lot.text.trim(),
                  date!,
                  center!,
                  responsible!,
                  next: next,
                  notes: notes.text.trim(),
                ),
                stock,
                c,
              );
              toast(context, 'Vacunación registrada');
              Navigator.pop(context);
            }, icon: Icons.save_outlined),
          ],
        ),
      ),
    );
  }
}

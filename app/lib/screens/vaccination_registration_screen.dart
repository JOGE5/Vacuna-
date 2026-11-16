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
  final notes = TextEditingController();
  String? campaign, dose, lot;
  DateTime? next;
  String query = '';
  AppStore? store;
  Appointment? preparedAppointment;

  @override
  void dispose() {
    store?.cancelAppointmentPreparation(preparedAppointment);
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    store = s;
    preparedAppointment ??= s.selectedAppointment;
    final p = s.selectedPatient;
    final active = s.campaigns.where((c) => c.status == 'Activa').toList();
    final selectedAppointment = s.selectedAppointment;
    final chosenCampaign =
        campaign ??
        (selectedAppointment == null
            ? null
            : active
                      .where(
                        (c) =>
                            c.vaccine == selectedAppointment.vaccine &&
                            c.center == selectedAppointment.center,
                      )
                      .firstOrNull
                      ?.name ??
                  'Sin campaña');
    final selected = active.where((c) => c.name == chosenCampaign);
    final c = selected.isEmpty ? null : selected.first;
    final targetVaccine = c?.vaccine ?? selectedAppointment?.vaccine;
    final targetCenter = c?.center ?? selectedAppointment?.center;
    final lots =
        targetVaccine == null || targetCenter == null
              ? <Stock>[]
              : s.availableStocks
                    .where(
                      (e) =>
                          e.vaccine == targetVaccine &&
                          e.center == targetCenter,
                    )
                    .toList()
          ..sort((a, b) => a.expiry.compareTo(b.expiry));
    final matches = s.patients.where(
      (e) =>
          '${e.name} ${e.document}'.toLowerCase().contains(query.toLowerCase()),
    );
    return PageShell(
      title: 'Registrar vacunación',
      back: true,
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecciona paciente, campaña, dosis y lote.'),
            gap,
            SearchBox(
              'Buscar por nombre o documento',
              (v) => setState(() => query = v),
            ),
            if (query.isNotEmpty)
              Panel(
                child: Column(
                  children: matches
                      .map(
                        (e) => ListTile(
                          title: Text(e.name),
                          subtitle: Text(e.document),
                          onTap: () => setState(() {
                            s.selectedPatient = e;
                            query = '';
                          }),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (p != null)
              Panel(
                child: ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(p.name),
                  subtitle: Text(p.document),
                ),
              ),
            if (active.isEmpty)
              const Notice(
                'No hay campañas activas hoy. Revisa las fechas de las campañas.',
                warning: true,
              ),
            Panel(
              child: Column(
                children: [
                  const SectionTitle('Aplicación', Icons.vaccines_outlined),
                  SelectField(
                    'Campaña',
                    [
                      if (selectedAppointment != null) 'Sin campaña',
                      ...active.map((e) => e.name),
                    ],
                    chosenCampaign,
                    (v) => setState(() {
                      campaign = v;
                      lot = null;
                    }),
                  ),
                  if (c != null)
                    Notice(
                      '${c.vaccine} · ${c.center} · ${shortDate(s.now())}\nResponsable: ${s.currentUser.name}',
                    ),
                  if (c == null && selectedAppointment != null)
                    Notice(
                      '${selectedAppointment.vaccine} · ${selectedAppointment.center} · ${shortDate(s.now())}',
                    ),
                  SelectField(
                    'Dosis',
                    const ['Dosis 1', 'Dosis 2', 'Dosis de refuerzo'],
                    dose,
                    (v) => setState(() => dose = v),
                  ),
                  SelectField(
                    'Lote (vence primero)',
                    lots
                        .map(
                          (e) =>
                              '${e.lot} · vence ${shortDate(e.expiry)} · ${e.quantity} dosis',
                        )
                        .toList(),
                    lot,
                    (v) => setState(() => lot = v),
                    key: ValueKey(c?.name),
                  ),
                  if (targetVaccine != null && lots.isEmpty)
                    const Notice(
                      'No hay lotes válidos de esta vacuna en el centro de la campaña.',
                      warning: true,
                    ),
                  InputField('Observaciones', notes, lines: 2, validator: null),
                  DateField(
                    'Próxima cita (opcional)',
                    next,
                    (v) => setState(() => next = v),
                    validator: (_) => next != null && !next!.isAfter(s.now())
                        ? 'La cita debe ser posterior a hoy'
                        : null,
                  ),
                ],
              ),
            ),
            ActionButton('Guardar vacunación', () {
              if (!form.currentState!.validate()) return;
              if (p == null ||
                  (c == null && selectedAppointment == null) ||
                  lot == null) {
                toast(context, 'Selecciona paciente, campaña y lote');
                return;
              }
              if (c != null && c.status != 'Activa') {
                toast(context, 'La campaña ya no está activa');
                return;
              }
              final stock = lots.firstWhere(
                (e) => lot!.startsWith('${e.lot} ·'),
              );
              if (stock.quantity <= 0 ||
                  s.isExpired(stock) ||
                  stock.withdrawn) {
                toast(context, 'El lote ya no está disponible');
                return;
              }
              s.addVaccination(
                Vaccination(
                  p,
                  targetVaccine!,
                  dose!,
                  stock.lot,
                  s.now(),
                  targetCenter!,
                  s.currentUser.name,
                  campaign: c,
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

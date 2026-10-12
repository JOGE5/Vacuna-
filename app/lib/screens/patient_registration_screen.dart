import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/validators.dart';
import '../models/entities.dart';
import '../widgets/common.dart';
import '../widgets/form_fields.dart';
import '../widgets/page_shell.dart';

class PatientRegistrationScreen extends StatefulWidget {
  const PatientRegistrationScreen({super.key});
  @override
  State<PatientRegistrationScreen> createState() =>
      _PatientRegistrationScreenState();
}

class _PatientRegistrationScreenState extends State<PatientRegistrationScreen> {
  final form = GlobalKey<FormState>();
  final first = TextEditingController(),
      last = TextEditingController(),
      doc = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController(),
      emergency = TextEditingController();
  DateTime? birth;
  String? sex;
  @override
  void dispose() {
    for (final c in [first, last, doc, phone, address, emergency]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return PageShell(
      title: 'Nuevo paciente',
      back: true,
      child: Form(
        key: form,
        child: Column(
          children: [
            Panel(
              child: Column(
                children: [
                  const SectionTitle('Datos personales', Icons.person_outline),
                  InputField('Nombres*', first, icon: Icons.person_outline),
                  InputField('Apellidos*', last, icon: Icons.people_outline),
                  InputField(
                    'Documento*',
                    doc,
                    icon: Icons.badge_outlined,
                    validator: (v) {
                      final e = Validators.document(v);
                      if (e != null) return e;
                      return s.patients.any(
                            (p) =>
                                p.document.replaceAll(' ', '').toLowerCase() ==
                                v!.replaceAll(' ', '').toLowerCase(),
                          )
                          ? 'Este documento ya está registrado'
                          : null;
                    },
                  ),
                  DateField(
                    'Fecha de nacimiento*',
                    birth,
                    (v) => setState(() => birth = v),
                    last: DateTime.now(),
                    validator: (_) => birth == null
                        ? 'Selecciona una fecha'
                        : birth!.isAfter(DateTime.now())
                        ? 'La fecha no puede estar en el futuro'
                        : null,
                  ),
                  SelectField(
                    'Sexo*',
                    const ['Femenino', 'Masculino', 'Otro'],
                    sex,
                    (v) => setState(() => sex = v),
                  ),
                ],
              ),
            ),
            Panel(
              child: Column(
                children: [
                  const SectionTitle('Contacto', Icons.phone_outlined),
                  InputField(
                    'Teléfono',
                    phone,
                    validator: Validators.phone,
                    icon: Icons.phone_outlined,
                    keyboard: TextInputType.phone,
                  ),
                  InputField(
                    'Dirección',
                    address,
                    validator: null,
                    icon: Icons.location_on_outlined,
                  ),
                  InputField(
                    'Contacto de emergencia',
                    emergency,
                    validator: null,
                    icon: Icons.person_outline,
                  ),
                ],
              ),
            ),
            const Notice(
              'Usa los datos solo para la atención y seguimiento de vacunación',
            ),
            ActionButton('Guardar paciente', () {
              if (!form.currentState!.validate()) return;
              s.addPatient(
                Patient(
                  first.text.trim(),
                  last.text.trim(),
                  doc.text.trim(),
                  birth!,
                  sex: sex!,
                  phone: phone.text.trim(),
                  address: address.text.trim(),
                  emergency: emergency.text.trim(),
                ),
              );
              toast(context, 'Paciente registrado');
              Navigator.pop(context);
            }, icon: Icons.save_outlined),
          ],
        ),
      ),
    );
  }
}

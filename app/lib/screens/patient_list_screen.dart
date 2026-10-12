import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/page_shell.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});
  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context),
        list = s.patients.where(
          (p) => '${p.name} ${p.document}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        );
    return PageShell(
      navIndex: 2,
      title: 'Pacientes',
      actions: [
        IconButton(
          onPressed: () => go(context, '/patient/new'),
          icon: const Icon(Icons.person_add_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleMark(icon: Icons.people_outline),
              const SizedBox(width: 10),
              Text(
                '${128 + s.patients.length - 3}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Text(
                ' personas registradas',
                style: TextStyle(color: muted),
              ),
            ],
          ),
          gap,
          SearchBox(
            'Buscar por nombre o documento',
            (v) => setState(() => query = v),
          ),
          ...list.map(
            (p) => Panel(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final info = Row(
                    children: [
                      CircleMark(text: p.initials, size: 45),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              p.document,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                  final history = ActionButton(
                    'Ver historial',
                    () {
                      s.selectedPatient = p;
                      go(context, '/history');
                    },
                    outlined: true,
                    icon: Icons.description_outlined,
                  );
                  final register = ActionButton('Registrar vacunación', () {
                    s.selectedPatient = p;
                    go(context, '/vaccination');
                  }, icon: Icons.health_and_safety_outlined);
                  if (constraints.maxWidth > 440)
                    return Row(
                      children: [
                        Expanded(child: info),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 190,
                          child: Column(
                            children: [
                              history,
                              const SizedBox(height: 6),
                              register,
                            ],
                          ),
                        ),
                      ],
                    );
                  return Column(
                    children: [
                      info,
                      gap,
                      Row(
                        children: [
                          Expanded(child: history),
                          const SizedBox(width: 8),
                          Expanded(child: register),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (list.isEmpty) const Notice('No se encontraron pacientes'),
          ActionButton(
            'Nuevo paciente',
            () => go(context, '/patient/new'),
            icon: Icons.person_add_outlined,
          ),
        ],
      ),
    );
  }
}

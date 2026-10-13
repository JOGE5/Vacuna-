import 'package:flutter/material.dart';
import '../core/app_store.dart';
import '../core/validators.dart';
import '../models/entities.dart';
import 'common.dart';
import 'form_fields.dart';
import 'page_shell.dart';

class CampaignForm extends StatefulWidget {
  const CampaignForm({super.key, this.edit = false});
  final bool edit;
  @override
  State<CampaignForm> createState() => _CampaignFormState();
}

class _CampaignFormState extends State<CampaignForm> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      description = TextEditingController(),
      goal = TextEditingController();
  String? vaccine, target, center, responsible;
  String status = 'Activa';
  DateTime? start, end;
  Campaign? original;
  bool loaded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded) {
      if (widget.edit) {
        original = StoreScope.of(context).selectedCampaign;
        final c = original!;
        name.text = c.name;
        description.text = c.description;
        goal.text = '${c.goal}';
        vaccine = c.vaccine;
        target = c.target;
        center = c.center;
        responsible = c.responsible;
        status = c.status;
        start = c.start;
        end = c.end;
      }
      loaded = true;
    }
  }

  Widget _pair(Widget first, Widget second) => widget.edit
      ? Column(children: [first, second])
      : Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    goal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    return PageShell(
      title: widget.edit ? 'Editar campaña' : 'Nueva campaña',
      back: true,
      child: Form(
        key: form,
        child: Column(
          children: [
            Panel(
              child: Column(
                children: [
                  const SectionTitle('Información general', Icons.info_outline),
                  InputField(
                    'Nombre de la campaña',
                    name,
                    validator: (v) {
                      final e = Validators.required(v);
                      if (e != null) return e;
                      return s.campaigns.any(
                            (c) =>
                                c != original &&
                                c.name.toLowerCase() == v!.trim().toLowerCase(),
                          )
                          ? 'Ya existe una campaña con este nombre'
                          : null;
                    },
                  ),
                  InputField('Descripción', description, lines: 2),
                  _pair(
                    SelectField(
                      'Vacuna',
                      const [
                        'Influenza estacional',
                        'SRP',
                        'Hepatitis B',
                        'COVID-19',
                      ],
                      vaccine,
                      (v) => setState(() => vaccine = v),
                    ),
                    SelectField(
                      'Población objetivo',
                      const [
                        'Personas mayores de 60 años',
                        'Niñas y niños de 1 a 5 años',
                        'Población general',
                      ],
                      target,
                      (v) => setState(() => target = v),
                    ),
                  ),
                  if (widget.edit)
                    SelectField(
                      'Estado',
                      const ['Activa', 'Próxima', 'Finalizada'],
                      status,
                      (v) => setState(() => status = v!),
                    ),
                ],
              ),
            ),
            Panel(
              child: Column(
                children: [
                  const SectionTitle(
                    'Planificación',
                    Icons.calendar_month_outlined,
                  ),
                  _pair(
                    DateField(
                      'Fecha de inicio',
                      start,
                      (v) => setState(() => start = v),
                    ),
                    DateField(
                      'Fecha de fin',
                      end,
                      (v) => setState(() => end = v),
                      validator: (_) => end == null
                          ? 'Selecciona una fecha'
                          : start != null && end!.isBefore(start!)
                          ? 'La fecha final no puede ser anterior a la inicial'
                          : null,
                    ),
                  ),
                  const Notice(
                    'La fecha final no puede ser anterior a la inicial',
                  ),
                ],
              ),
            ),
            Panel(
              child: Column(
                children: [
                  const SectionTitle('Operación', Icons.people_outline),
                  _pair(
                    SelectField(
                      'Centro',
                      s.centers.map((e) => e.name).toList(),
                      center,
                      (v) => setState(() => center = v),
                    ),
                    SelectField(
                      'Responsable',
                      s.users
                          .where((u) => u.active)
                          .map((e) => e.name)
                          .toList(),
                      responsible,
                      (v) => setState(() => responsible = v),
                    ),
                  ),
                  InputField(
                    'Meta de dosis',
                    goal,
                    validator: (v) {
                      final e = Validators.positive(v);
                      if (e != null) return e;
                      if (original != null && int.parse(v!) < original!.applied)
                        return 'La meta no puede ser menor a las dosis aplicadas';
                      return null;
                    },
                    keyboard: TextInputType.number,
                  ),
                ],
              ),
            ),
            if (widget.edit)
              ActionButton(
                'Cancelar',
                () => Navigator.pop(context),
                icon: Icons.close,
                outlined: true,
              ),
            gap,
            ActionButton(
              widget.edit ? 'Guardar cambios' : 'Crear campaña',
              () {
                if (!form.currentState!.validate()) return;
                s.saveCampaign(
                  Campaign(
                    name: name.text.trim(),
                    description: description.text.trim(),
                    vaccine: vaccine!,
                    target: target!,
                    center: center!,
                    responsible: responsible!,
                    start: start!,
                    end: end!,
                    goal: int.parse(goal.text),
                    status: status,
                    applied: original?.applied ?? 0,
                  ),
                  original,
                );
                toast(
                  context,
                  widget.edit ? 'Campaña actualizada' : 'Campaña creada',
                );
                Navigator.pop(context);
              },
              icon: Icons.save_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

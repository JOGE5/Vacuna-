import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_store.dart';
import '../core/validators.dart';
import '../models/entities.dart';
import '../widgets/common.dart';
import '../widgets/page_shell.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.center});
  final VaccinationCenter center;
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final document = TextEditingController();
  DateTime? day, slot;
  String? vaccine;
  Appointment? result;

  @override
  void dispose() {
    name.dispose();
    document.dispose();
    super.dispose();
  }

  String timeLabel(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = StoreScope.of(context);
    final days = s.bookingDays(widget.center).toList();
    final vaccines = s.availableStocks
        .where((stock) => stock.center == widget.center.name)
        .map((stock) => stock.vaccine)
        .toSet()
        .toList();
    return PageShell(
      title: 'Reservar turno',
      back: true,
      child: result != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Turno confirmado',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                gap,
                SelectableText(result!.summary),
                gap,
                ActionButton('Copiar resumen', () async {
                  await Clipboard.setData(ClipboardData(text: result!.summary));
                  if (context.mounted) toast(context, 'Resumen copiado');
                }, icon: Icons.copy_outlined),
              ],
            )
          : Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.center.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  gap,
                  const Text('Elige uno de los próximos 7 días de atención.'),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final value in days)
                        ChoiceChip(
                          label: Text('${value.day}/${value.month}'),
                          selected: day == value,
                          onSelected: (_) => setState(() {
                            day = value;
                            slot = null;
                          }),
                        ),
                    ],
                  ),
                  gap,
                  if (day != null) ...[
                    const Text('Franja de 30 min'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final value in s.bookingSlots(widget.center, day!))
                          ChoiceChip(
                            label: Text(
                              '${timeLabel(value)}${s.slotCount(widget.center, value) >= 6 ? ' · Lleno' : ''}',
                            ),
                            selected: slot == value,
                            onSelected: s.canBook(widget.center, value)
                                ? (_) => setState(() => slot = value)
                                : null,
                          ),
                      ],
                    ),
                    gap,
                  ],
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo',
                    ),
                    validator: (v) {
                      if (Validators.required(v) != null)
                        return Validators.required(v);
                      return v!.trim().split(RegExp(r'\s+')).length < 2
                          ? 'Introduce nombre y apellido'
                          : null;
                    },
                  ),
                  TextFormField(
                    controller: document,
                    decoration: const InputDecoration(labelText: 'CI'),
                    validator: Validators.document,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: vaccine,
                    decoration: const InputDecoration(labelText: 'Vacuna'),
                    items: vaccines
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => vaccine = v),
                    validator: (v) =>
                        v == null ? 'Selecciona una vacuna' : null,
                  ),
                  gap,
                  ActionButton('Confirmar turno', () {
                    if (!form.currentState!.validate()) return;
                    if (slot == null) {
                      toast(context, 'Selecciona una franja disponible');
                      return;
                    }
                    try {
                      setState(
                        () => result = s.reserve(
                          widget.center,
                          slot!,
                          name.text,
                          document.text,
                          vaccine!,
                        ),
                      );
                    } on StateError {
                      toast(context, 'La franja ya no está disponible');
                    }
                  }, icon: Icons.check),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/validators.dart';
import 'common.dart';

class InputField extends StatelessWidget {
  const InputField(
    this.label,
    this.controller, {
    super.key,
    this.validator = Validators.required,
    this.icon,
    this.keyboard,
    this.lines = 1,
    this.obscure = false,
  });
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final IconData? icon;
  final TextInputType? keyboard;
  final int lines;
  final bool obscure;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboard,
          maxLines: lines,
          obscureText: obscure,
          decoration: InputDecoration(
            prefixIcon: icon == null ? null : Icon(icon, size: 20),
          ),
        ),
      ],
    ),
  );
}

class SelectField extends StatelessWidget {
  const SelectField(
    this.label,
    this.items,
    this.value,
    this.onChanged, {
    super.key,
    this.required = true,
  });
  final String label;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool required;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 5),
        DropdownButtonFormField<String>(
          initialValue: items.contains(value) ? value : null,
          isExpanded: true,
          decoration: const InputDecoration(),
          hint: Text(
            'Seleccionar ${label.toLowerCase()}',
            style: const TextStyle(fontSize: 12),
          ),
          items: items
              .toSet()
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          validator: required ? Validators.required : null,
        ),
      ],
    ),
  );
}

class DateField extends StatelessWidget {
  const DateField(
    this.label,
    this.value,
    this.onChanged, {
    super.key,
    this.last,
    this.first,
    this.validator,
  });
  final String label;
  final DateTime? value, last, first;
  final ValueChanged<DateTime> onChanged;
  final String? Function(DateTime?)? validator;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: FormField<DateTime>(
      initialValue: value,
      validator: validator ?? (v) => v == null ? 'Selecciona una fecha' : null,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          InkWell(
            onTap: () async {
              final start = first ?? DateTime(1900),
                  end = last ?? DateTime(2100);
              final initial = value ?? DateTime.now();
              final d = await showDatePicker(
                context: context,
                initialDate: initial.isBefore(start)
                    ? start
                    : initial.isAfter(end)
                    ? end
                    : initial,
                firstDate: start,
                lastDate: end,
              );
              if (d != null) {
                state.didChange(d);
                onChanged(d);
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
                errorText: state.errorText,
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
              ),
              child: Text(
                value == null ? 'Seleccionar fecha' : dateLabel(value!),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

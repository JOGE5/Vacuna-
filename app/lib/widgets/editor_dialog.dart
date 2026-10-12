import 'package:flutter/material.dart';
import '../core/validators.dart';
import 'form_fields.dart';

Future<Map<String, String>?> editorDialog(
  BuildContext context,
  String title,
  List<String> fields, {
  Map<String, String> initial = const {},
}) async {
  final key = GlobalKey<FormState>();
  final controllers = {
    for (final f in fields) f: TextEditingController(text: initial[f] ?? ''),
  };
  final result = await showDialog<Map<String, String>>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: fields
                  .map(
                    (f) => InputField(
                      f,
                      controllers[f]!,
                      validator: f == 'Correo'
                          ? Validators.email
                          : f == 'Cantidad'
                          ? Validators.positive
                          : f == 'Contraseña'
                          ? Validators.password
                          : Validators.required,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (key.currentState!.validate())
              Navigator.pop(c, {
                for (final f in fields) f: controllers[f]!.text.trim(),
              });
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
  // La animación de cierre termina antes de liberar los controladores.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  for (final controller in controllers.values) {
    controller.dispose();
  }
  return result;
}

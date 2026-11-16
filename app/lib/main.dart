import 'package:flutter/material.dart';
import 'app.dart';
import 'core/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VacunaSupabase.initialize();
  runApp(const VacunaPlusApp());
}

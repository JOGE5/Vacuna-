import 'package:flutter/material.dart';
import 'app.dart';
import 'core/supabase_config.dart';
import 'core/supabase_app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const demo = bool.fromEnvironment('VACUNAPLUS_DEMO');
  if (demo) {
    runApp(const VacunaPlusApp());
    return;
  }
  await VacunaSupabase.initialize();
  runApp(VacunaPlusApp(store: SupabaseAppStore()));
}

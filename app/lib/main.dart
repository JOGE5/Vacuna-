import 'package:flutter/material.dart';
import 'app.dart';
import 'core/supabase_config.dart';
import 'core/app_store.dart';
import 'core/supabase_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await VacunaSupabase.initialize();
  runApp(VacunaPlusApp(store: AppStore(auth: const SupabaseAuthService())));
}

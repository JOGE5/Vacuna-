import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente de Supabase para VacunaPlus.
/// Solo se utiliza la clave publicable (nunca una clave secreta).
class VacunaSupabase {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://eupodocpqoedinvpdgxk.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_3XbYBpdghqX1x9mea2l3EA_1HIrVtXe',
  );

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}

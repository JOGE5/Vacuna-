import 'package:flutter/material.dart';
import 'core/app_store.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/campaign_list_screen.dart';
import 'screens/create_campaign_screen.dart';
import 'screens/campaign_detail_screen.dart';
import 'screens/edit_campaign_screen.dart';
import 'screens/patient_registration_screen.dart';
import 'screens/patient_list_screen.dart';
import 'screens/vaccination_registration_screen.dart';
import 'screens/vaccination_history_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/centers_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/users_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/more_screen.dart';

class VacunaPlusApp extends StatefulWidget {
  const VacunaPlusApp({super.key, this.initialRoute = '/', this.store});
  final String initialRoute;
  final AppStore? store;
  @override
  State<VacunaPlusApp> createState() => _VacunaPlusAppState();
}

class _VacunaPlusAppState extends State<VacunaPlusApp> {
  late final AppStore store = widget.store ?? AppStore();
  @override
  void dispose() {
    if (widget.store == null) store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StoreScope(
    store: store,
    child: MaterialApp(
      title: 'VacunaPlus',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      initialRoute: widget.initialRoute,
      routes: {
        '/': (c) => const LoginScreen(),
        '/home': (c) => const DashboardScreen(),
        '/campaigns': (c) => const CampaignListScreen(),
        '/campaign/new': (c) => const CreateCampaignScreen(),
        '/campaign/detail': (c) => const CampaignDetailScreen(),
        '/campaign/edit': (c) => const EditCampaignScreen(),
        '/patient/new': (c) => const PatientRegistrationScreen(),
        '/patients': (c) => const PatientListScreen(),
        '/vaccination': (c) => const VaccinationRegistrationScreen(),
        '/history': (c) => const VaccinationHistoryScreen(),
        '/inventory': (c) => const InventoryScreen(),
        '/centers': (c) => const CentersScreen(),
        '/reports': (c) => const ReportsScreen(),
        '/users': (c) => const UsersScreen(),
        '/profile': (c) => const ProfileScreen(),
        '/more': (c) => const MoreScreen(),
      },
    ),
  );
}

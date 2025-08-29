import 'package:flutter/material.dart';
import 'ecrans/admin/tableau_de_bord_admin.dart';
import 'ecrans/admin/vehicules.dart';
import 'ecrans/admin/utilisateurs.dart';
import 'ecrans/admin/alertes.dart';
import 'ecrans/admin/missions.dart';
import 'ecrans/admin/documents.dart';
import 'ecrans/admin/parametres.dart';
import 'ecrans/admin/trajets.dart';
import 'ecrans/admin/statistiques.dart' as admin;
import 'ecrans/admin/rapports.dart';
import 'package:flotte/services/notification_service.dart';
import 'connexion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le service de notifications
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion de Flotte',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => ConnexionPage(),
        '/admin/dashboard': (context) => TableauDeBordAdmin(),
        '/admin/vehicules': (context) => const VehiculePage(),
        '/admin/utilisateurs': (context) => const UtilisateursPage(),
        '/admin/alertes': (context) => const AlertesPage(),
        '/admin/missions': (context) => const MissionsPage(),
        '/admin/trajets': (context) => const TrajetsAdminPage(),
        '/admin/statistiques': (context) => const admin.StatistiquesPage(),
        '/admin/documents': (context) => const DocumentsPage(),
        '/admin/parametres': (context) => const ParametresPage(),
        '/admin/rapports': (context) => RapportsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flotte/services/notification_service.dart';
import 'package:flotte/connexion.dart';
import 'package:flotte/ecrans/admin/tableau_de_bord_admin.dart';
import 'package:flotte/ecrans/admin/vehicules.dart';
import 'package:flotte/ecrans/admin/utilisateurs.dart';
import 'package:flotte/ecrans/admin/alertes.dart';
import 'package:flotte/ecrans/admin/missions.dart';
import 'package:flotte/ecrans/admin/documents.dart';
import 'package:flotte/ecrans/admin/parametres.dart';
import 'package:flotte/ecrans/admin/trajets_modern.dart';
import 'package:flotte/ecrans/admin/statistiques.dart' as admin;
import 'package:flotte/ecrans/admin/rapports.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion de Flotte',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ConnexionPage(),
        '/admin/dashboard': (context) => TableauDeBordAdmin(),
        '/admin/vehicules': (context) => VehiculePage(),
        '/admin/utilisateurs': (context) => UtilisateursPage(),
        '/admin/alertes': (context) => AlertesPage(),
        '/admin/missions': (context) => MissionsPage(),
        '/admin/trajets': (context) => TrajetsModernPage(),
        '/admin/statistiques': (context) => admin.StatistiquesPage(),
        '/admin/documents': (context) => DocumentsPage(),
        '/admin/parametres': (context) => ParametresPage(),
        '/admin/rapports': (context) => RapportsScreen(),  // Supprimé const ici
        '/recuperation-mot-de-passe': (context) => RecuperationMotDePasse(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class RecuperationMotDePasse extends StatelessWidget {
  const RecuperationMotDePasse({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Récupération de mot de passe')),
      body: const Center(child: Text('Page de récupération de mot de passe')),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le service de notifications
  final notificationService = NotificationService();
  await notificationService.init();

  runApp(const MyApp());
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'services/position_sender_service.dart';

import 'connexion.dart';
//import 'package:application_conducteur/ecrans/tableau_de_bord.dart';
import 'package:application_conducteur/ecrans/missions.dart';
import 'package:application_conducteur/ecrans/vehicules.dart';
import 'package:application_conducteur/ecrans/doc.dart';
import 'package:application_conducteur/ecrans/profil.dart';
import 'package:application_conducteur/ecrans/historiques.dart';
import 'package:application_conducteur/ecrans/alertes.dart';
import 'package:application_conducteur/ecrans/dashboard.dart';
import 'package:application_conducteur/ecrans/trajets.dart';
import 'package:application_conducteur/ecrans/settings_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PositionSenderService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Application Conducteur',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        primaryColor: const Color(0xFF6A4EC2),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A4EC2),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A4EC2),
          brightness: Brightness.dark,
        ),
      ),
      // Définition des routes
      initialRoute: '/',
      routes: {
        '/': (context) => const ConnexionPage(),
        '/dashboard': (context) => TableauDeBord(),
        '/missions': (context) => const MissionsPage(),
        '/vehicules': (context) => const VehiculesPage(),
        '/documents': (context) => DocumentsPage(),
        '/profil': (context) => ProfilPage(),
        '/historiques': (context) => HistoriquesPage(),
        '/alertes': (context) => AlertesPage(),
        '/trajets': (context) => TrajetsPage(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

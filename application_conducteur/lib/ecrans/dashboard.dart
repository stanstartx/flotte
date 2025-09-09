import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';
import 'package:application_conducteur/ecrans/missions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:application_conducteur/services/position_sender_service.dart';
import 'package:application_conducteur/widgets/google_maps_widget.dart';

// Palette de couleurs
const Color kGreenDark = Color(0xFF14532D);
const Color kGreen = Color(0xFF22C55E);
const Color kBlue = Color(0xFF2563EB);
const Color kOrange = Color(0xFFF59E42);
const Color kRed = Color(0xFFEF4444);
const Color kGreyText = Color(0xFF64748B);
const Color kBlack = Color(0xFF1E293B);
const Color kWhite = Colors.white;

class TableauDeBord extends StatelessWidget {
  const TableauDeBord({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final positionSender = Provider.of<PositionSenderService>(context);

    // Conducteur
    final Map<String, String?> conducteur = {
      'nom': 'Jean Kouassi',
      'avatar': null, // Mettre une URL si disponible
    };

    // Stats
    final stats = [
      {'label': 'À faire', 'count': 2, 'color': kBlue},
      {'label': 'Acceptées', 'count': 1, 'color': kGreen},
      {'label': 'Refusées', 'count': 0, 'color': kRed},
      {'label': 'Terminées', 'count': 5, 'color': kGreyText},
    ];

    // Notifications
    final notifications = [
      "🕘 Arrivez à 08h45 pour votre première mission.",
      "🛠 Prochain entretien dans 3 jours.",
    ];

    // Missions
    final missions = [
      {
        'trajet': 'Abobo → Plateau',
        'date': 'Aujourd\'hui',
        'heure': '09h00',
        'statut': 'À faire',
        'vehicule': {
          'marque': 'Toyota Hilux',
          'immatriculation': 'AB-1234-ZZ',
          'carburant': '70%',
          'kilometrage': '84 230 km',
          'prochainEntretien': '21 Juin 2025',
        },
      },
      {
        'trajet': 'Cocody → Treichville',
        'date': 'Hier',
        'heure': '14h30',
        'statut': 'Terminée',
        'vehicule': {
          'marque': 'Nissan Navara',
          'immatriculation': 'CD-5678-ZZ',
          'carburant': '50%',
          'kilometrage': '56 780 km',
          'prochainEntretien': '30 Juin 2025',
        },
      },
    ];

    return Scaffold(
      backgroundColor: kWhite,
      appBar:
          isMobile
              ? AppBar(
                backgroundColor: kWhite,
                surfaceTintColor: kWhite,
                elevation: 0,
                iconTheme: const IconThemeData(color: kBlue),
                title: Text(
                  'Tableau de bord',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: kBlack,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: kRed),
                    tooltip: 'Déconnexion',
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      Provider.of<PositionSenderService>(
                        context,
                        listen: false,
                      ).stop();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/',
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              )
              : null,
      drawer: isMobile ? const Menu() : null,
      body: Row(
        children: [
          if (!isMobile) const Menu(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      if (!isMobile)
                        Text(
                          'Tableau de bord',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Profil conducteur
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundImage:
                                conducteur['avatar'] != null
                                    ? NetworkImage(conducteur['avatar']!)
                                    : null,
                            child:
                                conducteur['avatar'] == null
                                    ? const Icon(
                                      Icons.person,
                                      size: 32,
                                      color: kWhite,
                                    )
                                    : null,
                            backgroundColor: kBlue,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bonjour, ${conducteur['nom']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: kBlack,
                                ),
                              ),
                              Text(
                                'Conducteur',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: kGreyText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Statistiques
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              stats
                                  .map(
                                    (s) => _AnimatedStatCard(
                                      label: s['label'] as String,
                                      count: s['count'] as int,
                                      color: s['color'] as Color,
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Notifications
                      Text(
                        'Notifications',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: kOrange,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children:
                            notifications
                                .map(
                                  (notif) => _NotificationCard(message: notif),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 30),

                      // Localisation
                      Text(
                        'Ma localisation',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: kGreenDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: const GoogleMapsWidget(),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Actions rapides
                      Text(
                        'Actions rapides',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: kBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _QuickAction(
                            icon: Icons.assignment,
                            label: "Missions",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MissionsPage(),
                                ),
                              );
                            },
                          ),
                          _QuickAction(
                            icon: Icons.warning_amber,
                            label: "Incident",
                            onTap: () {},
                          ),
                          _QuickAction(
                            icon: Icons.car_repair,
                            label: "Mon véhicule",
                            onTap: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Missions
                      Text(
                        'Missions en cours / récentes',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: kBlue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children:
                            missions
                                .map((m) => _MissionCardPremium(mission: m))
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Statistique animée
class _AnimatedStatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _AnimatedStatCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      tween: Tween<double>(begin: 0, end: count.toDouble()),
      builder:
          (context, double value, child) => Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  value.toInt().toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(fontSize: 14, color: color),
                ),
              ],
            ),
          ),
    );
  }
}

// Carte notification
class _NotificationCard extends StatelessWidget {
  final String message;
  const _NotificationCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.notifications, color: kOrange),
        title: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
      ),
    );
  }
}

// Action rapide
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: kBlue, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mission premium avec badges colorés
class _MissionCardPremium extends StatelessWidget {
  final Map mission;
  const _MissionCardPremium({required this.mission});

  @override
  Widget build(BuildContext context) {
    final vehicule = mission['vehicule'] ?? {};
    String statut = mission['statut'] ?? '';
    Color statutColor;
    switch (statut) {
      case 'Terminée':
        statutColor = kGreen;
        break;
      case 'À faire':
        statutColor = kBlue;
        break;
      case 'Refusée':
        statutColor = kRed;
        break;
      case 'Acceptée':
        statutColor = kGreenDark;
        break;
      default:
        statutColor = kGreyText;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.directions_car, color: statutColor, size: 28),
              title: Text(
                mission['trajet'] ?? '',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text('${mission['date']} à ${mission['heure']}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statut,
                  style: GoogleFonts.poppins(
                    color: statutColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (vehicule.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.directions_car, color: kGreenDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${vehicule['marque']} | ${vehicule['immatriculation']}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _showVehiculeModal(context, vehicule);
                    },
                    child: const Text('🧾 Fiche véhicule'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showVehiculeModal(BuildContext context, Map vehicule) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            backgroundColor: kWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fiche Véhicule',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kGreenDark,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  ...[
                    'Marque',
                    'Immatriculation',
                    'Kilométrage',
                    'Carburant',
                    'Prochain entretien',
                  ].map(
                    (label) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              '$label :',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: kGreyText,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              vehicule[label.toLowerCase().replaceAll(
                                    ' ',
                                    '',
                                  )] ??
                                  vehicule[label] ??
                                  '',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.picture_as_pdf, color: kRed),
                        label: const Text(
                          'Exporter en PDF',
                          style: TextStyle(color: kRed),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kRed),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGreenDark,
                        ),
                        child: const Text('Fermer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

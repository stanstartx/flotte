import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:application_conducteur/ecrans/missions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:application_conducteur/services/location_service.dart';
import 'package:provider/provider.dart';
import 'package:application_conducteur/services/position_sender_service.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:application_conducteur/widgets/google_maps_widget.dart';

// Palette de couleurs
const Color kGreenDark = Color(0xFF14532D);
const Color kGreen = Color(0xFF22C55E);
const Color kBlue = Color(0xFF2563EB);
const Color kOrange = Color(0xFFF59E42);
const Color kRed = Color(0xFFEF4444);
const Color kGreyBg = Color(0xFFF3F4F6);
const Color kGreyText = Color(0xFF64748B);
const Color kBlack = Color(0xFF1E293B);

class TableauDeBord extends StatelessWidget {
  const TableauDeBord({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final positionSender = Provider.of<PositionSenderService>(context);
    final lastStatus = positionSender.lastStatus ?? '';
    Color iconColor;
    if (lastStatus.contains('envoyée')) {
      iconColor = kGreen;
    } else if (lastStatus.contains('simulée')) {
      iconColor = kOrange;
    } else if (lastStatus.contains('Erreur')) {
      iconColor = kRed;
    } else {
      iconColor = kGreyText;
    }

    // TODO: Récupérer les vraies données conducteur, missions, véhicule, notifications
    final conducteur = {
      'nom': 'Jean Kouassi',
      'avatar': null, // null = avatar par défaut
    };
    final stats = [
      {'label': 'À faire', 'count': 2, 'color': kBlue},
      {'label': 'Acceptées', 'count': 1, 'color': kGreen},
      {'label': 'Refusées', 'count': 0, 'color': kRed},
      {'label': 'Terminées', 'count': 5, 'color': kGreyText},
    ];
    final vehicule = {
      'marque': 'Toyota Hilux',
      'immatriculation': 'AB-1234-ZZ',
      'carburant': '70%',
      'kilometrage': '84 230 km',
      'prochainEntretien': '21 Juin 2025',
    };
    final notifications = [
      "🕘 Pensez à arriver à 08h45 pour votre première mission.",
      "🛠 Prochain entretien prévu dans 3 jours.",
    ];
    final missions = [
      {
        'trajet': 'Abobo → Plateau',
        'date': 'Aujourd\'hui',
        'heure': '09h00',
        'statut': 'À faire',
      },
      {
        'trajet': 'Cocody → Treichville',
        'date': 'Hier',
        'heure': '14h30',
        'statut': 'Terminée',
      },
    ];

    return Scaffold(
      backgroundColor: kGreyBg,
      appBar: isMobile
          ? AppBar(
              backgroundColor: kGreenDark,
              elevation: 0,
              title: Row(
                children: [
                  Hero(
                    tag: 'avatar',
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: kGreen,
                      backgroundImage: conducteur['avatar'] != null && (conducteur['avatar'] as String).isNotEmpty
                          ? NetworkImage(conducteur['avatar'] as String)
                          : null,
                      child: conducteur['avatar'] == null || (conducteur['avatar'] as String).isEmpty
                          ? Icon(Icons.person, color: Colors.white, size: 32)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    (conducteur['nom'] ?? '') as String,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              actions: [
                Tooltip(
                  message: lastStatus.isNotEmpty ? lastStatus : 'État inconnu',
                  child: Icon(Icons.my_location, color: iconColor),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Déconnexion',
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.clear();
                    Provider.of<PositionSenderService>(context, listen: false).stop();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Hero(
                                tag: 'avatar',
                                child: CircleAvatar(
                                  radius: 32,
                                  backgroundColor: kGreen,
                                  backgroundImage: conducteur['avatar'] != null && (conducteur['avatar'] as String).isNotEmpty
                                      ? NetworkImage(conducteur['avatar'] as String)
                                      : null,
                                  child: conducteur['avatar'] == null || (conducteur['avatar'] as String).isEmpty
                                      ? Icon(Icons.person, color: Colors.white, size: 32)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bienvenue,',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: kGreyText,
                                    ),
                                  ),
                                  Text(
                                    (conducteur['nom'] ?? '') as String,
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: kBlack,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (!isMobile)
                            Row(
                              children: [
                                Tooltip(
                                  message: lastStatus.isNotEmpty ? lastStatus : 'État inconnu',
                                  child: Icon(Icons.my_location, color: iconColor),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout),
                                  tooltip: 'Déconnexion',
                                  onPressed: () async {
                                    final prefs = await SharedPreferences.getInstance();
                                    await prefs.clear();
                                    Provider.of<PositionSenderService>(context, listen: false).stop();
                                    if (context.mounted) {
                                      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                                    }
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // STATISTIQUES
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: stats.map((s) => _StatCard(
                            label: (s['label'] ?? '') as String,
                            count: (s['count'] ?? 0) as int,
                            color: (s['color'] ?? kBlue) as Color,
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 30),

                                             // VÉHICULE
                       Card(
                         elevation: 5,
                         color: Colors.white,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                         child: Padding(
                           padding: const EdgeInsets.all(22),
                           child: Row(
                             children: [
                               Icon(Icons.directions_car, color: kGreenDark, size: 38),
                               const SizedBox(width: 18),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Text('Véhicule assigné', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: kGreenDark)),
                                     const SizedBox(height: 6),
                                     Text('${vehicule['marque']}  |  ${vehicule['immatriculation']}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
                                     Text('Kilométrage : ${vehicule['kilometrage']}', style: GoogleFonts.poppins(fontSize: 13, color: kGreyText)),
                                     Text('⛽ Carburant : ${vehicule['carburant']}', style: GoogleFonts.poppins(fontSize: 13, color: kGreyText)),
                                     Text('🛠 Prochain entretien : ${vehicule['prochainEntretien']}', style: GoogleFonts.poppins(fontSize: 13, color: kGreyText)),
                                   ],
                                 ),
                               ),
                               TextButton(
                                 onPressed: () {
                                   _showVehiculeDetailsModal(context, vehicule);
                                 },
                                 child: const Text('🧾 Fiche véhicule'),
                               ),
                             ],
                           ),
                         ),
                       ),
                      const SizedBox(height: 30),

                      // MAP
                      _MapWidget(),
                      const SizedBox(height: 30),

                                             // NOTIFICATIONS
                       Text('Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: kOrange)),
                       const SizedBox(height: 10),
                       ...notifications.map((notif) => Card(
                         color: Colors.white,
                         elevation: 2,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                         child: ListTile(
                           leading: Icon(Icons.notifications, color: kOrange),
                           title: Text(notif, style: GoogleFonts.poppins(fontSize: 14)),
                         ),
                       )),
                       const SizedBox(height: 30),

                       // MISSIONS RÉCENTES
                       Text('Missions récentes', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18, color: kBlue)),
                       const SizedBox(height: 10),
                       Card(
                         elevation: 3,
                         color: Colors.white,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                         child: Padding(
                           padding: const EdgeInsets.all(16),
                           child: Column(
                             children: [
                               ...missions.map((m) => ListTile(
                                 leading: Icon(Icons.directions_car, color: kBlue),
                                 title: Text(m['trajet']!, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                                 subtitle: Text('${m['date']} à ${m['heure']}'),
                                 trailing: _MissionStatusChip(statut: m['statut']!),
                               )),
                               Align(
                                 alignment: Alignment.centerRight,
                                 child: TextButton(
                                   onPressed: () {
                                     Navigator.push(context, MaterialPageRoute(builder: (_) => const MissionsPage()));
                                   },
                                   child: const Text('📦 Voir toutes les missions'),
                                 ),
                               ),
                             ],
                           ),
                         ),
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

  void _showVehiculeDetailsModal(BuildContext context, Map<String, String> vehicule) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Fiche Véhicule', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: kGreenDark)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
                const Divider(height: 30),
                _detailRow('Marque', vehicule['marque'] ?? ''),
                _detailRow('Immatriculation', vehicule['immatriculation'] ?? ''),
                _detailRow('Kilométrage', vehicule['kilometrage'] ?? ''),
                _detailRow('Carburant', vehicule['carburant'] ?? ''),
                _detailRow('Prochain entretien', vehicule['prochainEntretien'] ?? ''),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.picture_as_pdf, color: kRed),
                      label: const Text('Exporter en PDF', style: TextStyle(color: kRed)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: kRed)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: kGreenDark),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('$label :', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: kGreyText)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatCard({required this.label, required this.count, required this.color});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(right: 18),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22, color: color)),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 14, color: color)),
        ],
      ),
    );
  }
}

class _MissionStatusChip extends StatelessWidget {
  final String statut;
  const _MissionStatusChip({required this.statut});
  @override
  Widget build(BuildContext context) {
    Color color;
    switch (statut) {
      case 'Terminée':
        color = kGreen;
        break;
      case 'À faire':
        color = kBlue;
        break;
      case 'Refusée':
        color = kRed;
        break;
      case 'Acceptée':
        color = kGreenDark;
        break;
      default:
        color = kGreyText;
    }
    return Chip(
      label: Text(statut, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w600)),
      backgroundColor: color.withOpacity(0.12),
    );
  }
}

class _MapWidget extends StatefulWidget {
  const _MapWidget({super.key});
  @override
  State<_MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<_MapWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 300,
        child: GoogleMapsWidget(
          showCurrentLocation: true,
          height: 300,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:application_conducteur/services/mission_service.dart';
import 'package:application_conducteur/widgets/google_maps_widget.dart';
import 'package:application_conducteur/services/google_maps_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MissionsPage extends StatefulWidget {
  const MissionsPage({super.key});

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> missions = [];
  final List<Map<String, String>> notifications = [
    {
      'titre': 'Nouvelle mission ajoutée',
      'description': 'Vous avez une nouvelle mission de livraison à effectuer.',
      'date': '19 Juin 2025',
    },
    {
      'titre': 'Mise à jour de mission',
      'description':
          'La mission "Réparation véhicule B" est maintenant terminée.',
      'date': '18 Juin 2025',
    },
    {
      'titre': 'Rappel entretien',
      'description': 'Un entretien est prévu demain pour le véhicule C.',
      'date': '17 Juin 2025',
    },
  ];

  late TabController _tabController;
  String searchQuery = "";
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _fetchMissions();
  }

  Future<void> _fetchMissions() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await MissionService.fetchMissions();
      
      // Traiter les missions avec calcul des vraies distances
      final List<Map<String, dynamic>> processedMissions = [];
      
      for (final m in data) {
        // Logique de classement
        String statutLabel = '';
        final reponse = (m['reponse_conducteur'] ?? '').toLowerCase();
        final statutBackend = (m['statut'] ?? '').toLowerCase();
        if (statutBackend == 'terminee') {
          statutLabel = 'Terminée';
        } else if (reponse == 'acceptee') {
          statutLabel = 'Acceptée';
        } else if (reponse == 'refusee') {
          statutLabel = 'Refusée';
        } else {
          statutLabel = 'À faire';
        }
        
        // Calculer la vraie distance si les adresses sont disponibles
        String distanceText = m['distance_km']?.toString() ?? '';
        String durationText = '';
        
        if (m['lieu_depart'] != null && m['lieu_arrivee'] != null &&
            m['lieu_depart'].toString().isNotEmpty && m['lieu_arrivee'].toString().isNotEmpty) {
          try {
            final distanceData = await GoogleMapsService.calculateDistanceBetweenAddresses(
              origin: m['lieu_depart'].toString(),
              destination: m['lieu_arrivee'].toString(),
            );
            distanceText = distanceData['distance'];
            durationText = distanceData['duration'];
          } catch (e) {
            // En cas d'erreur, garder la distance du backend
            print('Erreur calcul distance: $e');
          }
        }
        
        processedMissions.add({
          'id': m['id'],
          'titre': m['raison'] ?? '',
          'depart': m['lieu_depart'] ?? '',
          'arrivee': m['lieu_arrivee'] ?? '',
          'date': (m['date_depart'] ?? '').toString().substring(0, 10),
          'heure': (m['date_depart'] ?? '').toString().substring(11, 16),
          'distance': distanceText,
          'duration': durationText,
          'statut': statutLabel,
          'description': m['raison'] ?? '',
        });
      }
      
      setState(() {
        missions = processedMissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _accepterMission(int missionId) async {
    try {
      await MissionService.accepterMission(missionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mission acceptée ✅'), backgroundColor: Color(0xFF22C55E)),
      );
      _fetchMissions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFDC2626)),
      );
    }
  }

  Future<void> _refuserMission(int missionId) async {
    try {
      await MissionService.refuserMission(missionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mission refusée ❌'), backgroundColor: Color(0xFFDC2626)),
      );
      _fetchMissions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: const Color(0xFFDC2626)),
      );
    }
  }

  Future<void> _ouvrirItineraireGoogleMaps(String depart, String arrivee) async {
    try {
      // Encoder les adresses pour l'URL
      final departEncoded = Uri.encodeComponent(depart);
      final arriveeEncoded = Uri.encodeComponent(arrivee);
      
      // URL Google Maps pour la navigation
      final url = 'https://www.google.com/maps/dir/?api=1&origin=$departEncoded&destination=$arriveeEncoded&travelmode=driving';
      
      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Impossible d\'ouvrir Google Maps');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ouverture de l\'itinéraire: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMissionDetails(Map<String, dynamic> mission) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.assignment, color: Color(0xFF6A4EC2)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mission['titre'] ?? 'Mission',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Carte avec itinéraire
            if (mission['depart'] != null && mission['arrivee'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RouteMapWidget(
                  origin: mission['depart'],
                  destination: mission['arrivee'],
                  height: 300,
                ),
              ),
            
            // Détails de la mission
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem('Départ', mission['depart'] ?? 'Non spécifié'),
                    _buildDetailItem('Arrivée', mission['arrivee'] ?? 'Non spécifié'),
                    _buildDetailItem('Date', mission['date'] ?? 'Non spécifié'),
                    _buildDetailItem('Heure', mission['heure'] ?? 'Non spécifié'),
                                         if (mission['distance'] != null && mission['distance'].isNotEmpty)
                       _buildDetailItem('Distance', mission['distance']),
                     if (mission['duration'] != null && mission['duration'].isNotEmpty)
                       _buildDetailItem('Durée estimée', mission['duration']),
                    _buildDetailItem('Statut', mission['statut'] ?? 'Non spécifié'),
                    if (mission['description'] != null && mission['description'].isNotEmpty)
                      _buildDetailItem('Description', mission['description']),
                  ],
                ),
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Bouton Itinéraire (toujours visible)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _ouvrirItineraireGoogleMaps(
                          mission['depart'] ?? '',
                          mission['arrivee'] ?? '',
                        );
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Ouvrir l\'itinéraire dans Google Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  
                  // Boutons Accepter/Refuser (si applicable)
                  if (mission['statut'] == 'À faire') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _accepterMission(mission['id']);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Accepter'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _refuserMission(mission['id']);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                            ),
                            child: const Text('Refuser'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'À faire':
        return const Color(0xFF14532D);
      case 'En cours':
        return const Color(0xFF2563EB);
      case 'Terminé':
        return const Color(0xFF22C55E);
      case 'Annulé':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  Widget missionCard(Map<String, dynamic> mission, {bool isMobile = false}) {
    final bool peutAccepterOuRefuser = mission['statut'] == 'À faire' || mission['statut'] == 'En attente';
    return GestureDetector(
      onTap: () => showMissionDetailsModal(context, mission),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2F855A).withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre + statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    mission['titre'],
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF14532D),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(mission['statut']).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    mission['statut'],
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: getStatusColor(mission['statut']),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 8 : 10),
            // Date + Heure
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  mission['date'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 20),
                const Icon(
                  Icons.access_time_outlined,
                  color: Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  mission['heure'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 10 : 12),
            // Départ -> Arrivée
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF14532D),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "${mission['depart']} ➜ ${mission['arrivee']}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF14532D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 6 : 8),
            // Distance et durée
            Row(
              children: [
                const Icon(
                  Icons.directions_car_filled_rounded,
                  color: Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mission['distance'] != null && mission['distance'].isNotEmpty)
                        Text(
                          "Distance : ${mission['distance']}",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (mission['duration'] != null && mission['duration'].isNotEmpty)
                        Text(
                          "Durée : ${mission['duration']}",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 10 : 14),
            // Bouton Itinéraire (toujours visible)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bouton Itinéraire
                ElevatedButton.icon(
                  onPressed: () => _ouvrirItineraireGoogleMaps(
                    mission['depart'] ?? '',
                    mission['arrivee'] ?? '',
                  ),
                  icon: const Icon(Icons.directions),
                  label: const Text('Itinéraire'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                
                // Boutons Accepter/Refuser (si applicable)
                if (peutAccepterOuRefuser)
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _accepterMission(mission['id']),
                        icon: const Icon(Icons.check),
                        label: const Text('Accepter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _refuserMission(mission['id']),
                        icon: const Icon(Icons.close),
                        label: const Text('Refuser'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFDC2626)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F855A).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: isMobile ? 18 : 22, color: color),
          SizedBox(width: isMobile ? 8 : 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 11 : 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: isMobile ? 15 : 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF14532D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsList(
    List<Map<String, dynamic>> missionsList, {
    bool isMobile = false,
  }) {
    if (missionsList.isEmpty) {
      return Center(
        child: Text(
          "Aucune mission ici.",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[500]),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.only(bottom: isMobile ? 24 : 12),
      itemCount: missionsList.length,
      separatorBuilder: (_, __) => SizedBox(height: isMobile ? 12 : 16),
      itemBuilder: (context, index) {
        return missionCard(missionsList[index], isMobile: isMobile);
      },
    );
  }

  Widget _buildNotificationsTab({bool isMobile = false}) {
    if (notifications.isEmpty) {
      return Center(
        child: Text(
          "Aucune notification pour le moment.",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[500]),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: isMobile ? 24 : 12),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => SizedBox(height: isMobile ? 12 : 16),
      itemBuilder: (context, index) {
        final notif = notifications[index];
        final bool isMission = notif['titre']!.toLowerCase().contains(
          'mission',
        );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2F855A).withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF14532D),
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif['titre'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF14532D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif['description'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notif['date'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isMission) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Mission acceptée ✅"),
                            backgroundColor: Color(0xFF22C55E),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text("Accepter"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Mission refusée ❌"),
                            backgroundColor: Color(0xFFDC2626),
                          ),
                        );
                      },
                      icon: const Icon(Icons.close),
                      label: const Text("Refuser"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void showMissionDetailsModal(
    BuildContext context,
    Map<String, dynamic> mission,
  ) {
    _showMissionDetails(mission);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    final filteredMissions =
        missions.where((mission) {
          return (mission['titre'] ?? '').toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              (mission['depart'] ?? '').toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              (mission['arrivee'] ?? '').toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
        }).toList();

    final groupedByStatus = <String, List<Map<String, dynamic>>>{};
    for (var mission in filteredMissions) {
      groupedByStatus.putIfAbsent(mission['statut'], () => []).add(mission);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: isMobile ? const Drawer(child: Menu()) : null,
      appBar:
          isMobile
              ? AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: const IconThemeData(color: Color(0xFF14532D)),
                title: Text(
                  "Mes missions",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF14532D),
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                centerTitle: false,
              )
              : null,
      body: Row(
        children: [
          if (!isMobile) const Menu(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 32,
                vertical: isMobile ? 12 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMobile) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            "Mes missions",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF14532D),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.assignment,
                          color: const Color(0xFF2563EB),
                          size: 30,
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],

                  // Barre recherche
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Rechercher une mission...",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF14532D),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF14532D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF14532D),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    style: GoogleFonts.poppins(color: const Color(0xFF14532D)),
                    cursorColor: const Color(0xFF14532D),
                  ),

                  SizedBox(height: isMobile ? 12 : 16),

                  // Statistiques
                  isMobile
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStatCard(
                            "Total",
                            missions.length.toString(),
                            Icons.list_alt,
                            const Color(0xFF14532D),
                            isMobile: true,
                          ),
                          SizedBox(height: 12),
                          _buildStatCard(
                            "À faire",
                            missions
                                .where((m) => m['statut'] == 'À faire')
                                .length
                                .toString(),
                            Icons.pending_actions,
                            const Color(0xFF14532D),
                            isMobile: true,
                          ),
                          SizedBox(height: 12),
                          _buildStatCard(
                            "Acceptées",
                            missions
                                .where((m) => m['statut'] == 'Acceptée')
                                .length
                                .toString(),
                            Icons.check_circle_outline,
                            const Color(0xFF2563EB),
                            isMobile: true,
                          ),
                          SizedBox(height: 12),
                          _buildStatCard(
                            "Refusées",
                            missions
                                .where((m) => m['statut'] == 'Refusée')
                                .length
                                .toString(),
                            Icons.cancel_outlined,
                            const Color(0xFFDC2626),
                            isMobile: true,
                          ),
                          SizedBox(height: 12),
                          _buildStatCard(
                            "Terminées",
                            missions
                                .where((m) => m['statut'] == 'Terminée')
                                .length
                                .toString(),
                            Icons.check_circle,
                            const Color(0xFF22C55E),
                            isMobile: true,
                          ),
                        ],
                      )
                      : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCard(
                            "Total",
                            missions.length.toString(),
                            Icons.list_alt,
                            const Color(0xFF14532D),
                          ),
                          _buildStatCard(
                            "À faire",
                            missions
                                .where((m) => m['statut'] == 'À faire')
                                .length
                                .toString(),
                            Icons.pending_actions,
                            const Color(0xFF14532D),
                          ),
                          _buildStatCard(
                            "Acceptées",
                            missions
                                .where((m) => m['statut'] == 'Acceptée')
                                .length
                                .toString(),
                            Icons.check_circle_outline,
                            const Color(0xFF2563EB),
                          ),
                          _buildStatCard(
                            "Refusées",
                            missions
                                .where((m) => m['statut'] == 'Refusée')
                                .length
                                .toString(),
                            Icons.cancel_outlined,
                            const Color(0xFFDC2626),
                          ),
                          _buildStatCard(
                            "Terminées",
                            missions
                                .where((m) => m['statut'] == 'Terminée')
                                .length
                                .toString(),
                            Icons.check_circle,
                            const Color(0xFF22C55E),
                          ),
                        ],
                      ),

                  SizedBox(height: 16),

                  // Tabs
                  Expanded(
                    child: DefaultTabController(
                      length: 6,
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            labelColor: const Color(0xFF14532D),
                            unselectedLabelColor: Colors.grey[600],
                            indicatorColor: const Color(0xFF14532D),
                            labelStyle: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                            tabs: const [
                              Tab(text: "À faire"),
                              Tab(text: "Acceptées"),
                              Tab(text: "Refusées"),
                              Tab(text: "Terminées"),
                              Tab(text: "Annulées"),
                              Tab(text: "Notifications"),
                            ],
                          ),
                          SizedBox(height: 12),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildMissionsList(
                                  groupedByStatus['À faire'] ?? [],
                                  isMobile: isMobile,
                                ),
                                _buildMissionsList(
                                  groupedByStatus['Acceptée'] ?? [],
                                  isMobile: isMobile,
                                ),
                                _buildMissionsList(
                                  groupedByStatus['Refusée'] ?? [],
                                  isMobile: isMobile,
                                ),
                                _buildMissionsList(
                                  groupedByStatus['Terminée'] ?? [],
                                  isMobile: isMobile,
                                ),
                                _buildMissionsList(
                                  groupedByStatus['Annulée'] ?? [],
                                  isMobile: isMobile,
                                ),
                                _buildNotificationsTab(isMobile: isMobile),
                              ],
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
        ],
      ),
    );
  }
}

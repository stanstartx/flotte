import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flotte/widgets/menu_admin/admin_menu.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flotte/config.dart';

class TrajetsModernPage extends StatefulWidget {
  const TrajetsModernPage({super.key});

  @override
  State<TrajetsModernPage> createState() => _TrajetsModernPageState();
}

class _TrajetsModernPageState extends State<TrajetsModernPage> {
  List<dynamic> conducteurs = [];
  List<dynamic> trajets = [];
  List<dynamic> positions = [];
  bool isLoading = true;
  String? errorMessage;
  int? selectedConducteurId;
  List<dynamic> trajetsConducteur = [];
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  LatLng? centerPosition;

  // Données pour les graphiques
  int totalConducteurs = 0;
  int conducteursEnLigne = 0;
  
  // Timer pour actualisation automatique
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        loadData();
      }
    });
  }

  Future<void> loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          errorMessage = 'Token d\'authentification non trouvé';
          isLoading = false;
        });
        return;
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // Charger les conducteurs avec leurs positions en temps réel
      final conducteursResponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/drivers/positions/'),
        headers: headers,
      );

      if (conducteursResponse.statusCode == 200) {
        final data = json.decode(conducteursResponse.body);
        conducteurs = data is List ? data : [];
        
        // Calculer les statistiques
        totalConducteurs = conducteurs.length;
        conducteursEnLigne = conducteurs.where((c) => c['is_online'] == true).length;
      } else {
        print('Erreur chargement conducteurs: ${conducteursResponse.statusCode}');
      }

      // Charger les trajets (missions) si un conducteur est sélectionné
      if (selectedConducteurId != null) {
        await _loadDriverTrips(selectedConducteurId!);
      }

      setState(() {
        isLoading = false;
      });

      // Initialiser la carte avec une position par défaut (Abidjan)
      centerPosition = const LatLng(AppConfig.defaultLatitude, AppConfig.defaultLongitude);
      _updateMapMarkers();

    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de connexion: $e';
        isLoading = false;
      });
      print("Erreur récupération données: $e");
    }
  }

  Future<void> _loadDriverTrips(int driverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) return;

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final tripsResponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/drivers/$driverId/trips/'),
        headers: headers,
      );

      if (tripsResponse.statusCode == 200) {
        final data = json.decode(tripsResponse.body);
        trajetsConducteur = data is List ? data : [];
      }
    } catch (e) {
      print("Erreur chargement trajets conducteur: $e");
    }
  }

  void _updateMapMarkers() {
    markers.clear();
    polylines.clear();

    // Ajouter les marqueurs des conducteurs avec leurs vraies positions
    for (var conducteur in conducteurs) {
      if (conducteur['last_position'] != null) {
        final pos = conducteur['last_position'];
        final isOnline = conducteur['is_online'] ?? false;
        final username = conducteur['username'] ?? 'Conducteur';
        final firstName = conducteur['first_name'] ?? '';
        final lastName = conducteur['last_name'] ?? '';
        final fullName = '$firstName $lastName'.trim();
        final displayName = fullName.isNotEmpty ? fullName : username;
        
        markers.add(
          Marker(
            markerId: MarkerId('conducteur_${conducteur['id']}'),
            position: LatLng(pos['latitude'], pos['longitude']),
            infoWindow: InfoWindow(
              title: displayName,
              snippet: isOnline ? 'En ligne' : 'Hors ligne',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              isOnline ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
            ),
            onTap: () => _onConducteurSelected(conducteur['id']),
          ),
        );
      }
    }

    // Ajouter les trajets du conducteur sélectionné
    if (selectedConducteurId != null) {
      _addTrajetsToMap();
    }

    setState(() {});
  }

  void _addTrajetsToMap() {
    if (selectedConducteurId == null) return;
    
    for (var trajet in trajetsConducteur) {
      // Utiliser les vraies coordonnées si disponibles
      if (trajet['depart_latitude'] != null && 
          trajet['depart_longitude'] != null &&
          trajet['arrivee_latitude'] != null && 
          trajet['arrivee_longitude'] != null) {
        
        var depart = LatLng(
          double.parse(trajet['depart_latitude'].toString()),
          double.parse(trajet['depart_longitude'].toString()),
        );
        var arrivee = LatLng(
          double.parse(trajet['arrivee_latitude'].toString()),
          double.parse(trajet['arrivee_longitude'].toString()),
        );
        
        markers.add(
          Marker(
            markerId: MarkerId('depart_${trajet['id']}'),
            position: depart,
            infoWindow: InfoWindow(
              title: 'Départ',
              snippet: trajet['lieu_depart'] ?? 'Point de départ',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
        
        markers.add(
          Marker(
            markerId: MarkerId('arrivee_${trajet['id']}'),
            position: arrivee,
            infoWindow: InfoWindow(
              title: 'Arrivée',
              snippet: trajet['lieu_arrivee'] ?? 'Point d\'arrivée',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );

        polylines.add(
          Polyline(
            polylineId: PolylineId('trajet_${trajet['id']}'),
            points: [depart, arrivee],
            color: Colors.blue,
            width: 3,
          ),
        );
      } else if (trajet['lieu_depart'] != null && trajet['lieu_arrivee'] != null) {
        // Fallback avec coordonnées fictives si les vraies coordonnées ne sont pas disponibles
        var depart = LatLng(
          AppConfig.defaultLatitude + (trajet['id'] * 0.01), 
          AppConfig.defaultLongitude + (trajet['id'] * 0.01)
        );
        var arrivee = LatLng(
          AppConfig.defaultLatitude + (trajet['id'] * 0.02), 
          AppConfig.defaultLongitude + (trajet['id'] * 0.02)
        );
        
        markers.add(
          Marker(
            markerId: MarkerId('depart_${trajet['id']}'),
            position: depart,
            infoWindow: InfoWindow(
              title: 'Départ',
              snippet: trajet['lieu_depart'],
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
        
        markers.add(
          Marker(
            markerId: MarkerId('arrivee_${trajet['id']}'),
            position: arrivee,
            infoWindow: InfoWindow(
              title: 'Arrivée',
              snippet: trajet['lieu_arrivee'],
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );

        polylines.add(
          Polyline(
            polylineId: PolylineId('trajet_${trajet['id']}'),
            points: [depart, arrivee],
            color: Colors.orange,
            width: 2,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
    }
  }

  void _onConducteurSelected(int conducteurId) async {
    setState(() {
      selectedConducteurId = conducteurId;
    });
    
    // Charger les trajets du conducteur sélectionné
    await _loadDriverTrips(conducteurId);
    
    _addTrajetsToMap();
    _updateMapMarkers();
  }

  void _onTrajetSelected(Map<String, dynamic> trajet) {
    // Centrer la carte sur le trajet sélectionné
    if (trajet['depart_latitude'] != null && trajet['depart_longitude'] != null) {
      var depart = LatLng(
        double.parse(trajet['depart_latitude'].toString()),
        double.parse(trajet['depart_longitude'].toString()),
      );
      mapController?.animateCamera(CameraUpdate.newLatLng(depart));
    } else if (trajet['lieu_depart'] != null && trajet['lieu_arrivee'] != null) {
      // Fallback avec coordonnées fictives
      var depart = LatLng(
        AppConfig.defaultLatitude + (trajet['id'] * 0.01), 
        AppConfig.defaultLongitude + (trajet['id'] * 0.01)
      );
      mapController?.animateCamera(CameraUpdate.newLatLng(depart));
    }
  }

  Widget _buildConducteursList() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF002244),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Conducteurs',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: conducteurs.length,
              itemBuilder: (context, index) {
                final conducteur = conducteurs[index];
                final isSelected = selectedConducteurId == conducteur['id'];
                final isOnline = conducteur['is_online'] ?? false;
                final username = conducteur['username'] ?? 'Inconnu';
                final firstName = conducteur['first_name'] ?? '';
                final lastName = conducteur['last_name'] ?? '';
                final fullName = '$firstName $lastName'.trim();
                final displayName = fullName.isNotEmpty ? fullName : username;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF002244).withOpacity(0.1) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF002244) : Colors.grey[200]!,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: isOnline ? Colors.green : Colors.grey,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002244),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOnline ? 'En ligne' : 'Hors ligne',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                        if (conducteur['last_position'] != null)
                          Text(
                            'Dernière position: ${DateFormat('dd/MM HH:mm').format(DateTime.parse(conducteur['last_position']['timestamp']))}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: isSelected ? const Color(0xFF002244) : Colors.grey,
                    ),
                    onTap: () => _onConducteurSelected(conducteur['id']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrajetsList() {
    if (selectedConducteurId == null) {
      return Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.route, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Sélectionnez un conducteur',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'pour voir ses trajets',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.route, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Trajets récents',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: trajetsConducteur.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.route, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun trajet trouvé',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: trajetsConducteur.length,
                    itemBuilder: (context, index) {
                      final trajet = trajetsConducteur[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.directions,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          title: Text(
                            trajet['raison'] ?? 'Trajet',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF002244),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${trajet['lieu_depart']} → ${trajet['lieu_arrivee']}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (trajet['date_depart'] != null)
                                Text(
                                  DateFormat('dd/MM HH:mm').format(DateTime.parse(trajet['date_depart'])),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              if (trajet['distance_km'] != null)
                                Text(
                                  'Distance: ${trajet['distance_km']} km',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          onTap: () => _onTrajetSelected(trajet),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      width: 300,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.people, color: Colors.blue[700], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Total Conducteurs',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    totalConducteurs.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF002244),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.wifi, color: Colors.green[700], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'En ligne',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    conducteursEnLigne.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF002244),
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

  Widget _buildChart() {
    return Container(
      width: 300, // Largeur fixe pour contraindre le graphique
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Répartition des conducteurs',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF002244),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Barre de progression pour conducteurs en ligne
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: totalConducteurs > 0 
                            ? (conducteursEnLigne / totalConducteurs) * 300 // Utilisation de la largeur fixe
                            : 0,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      Center(
                        child: Text(
                          'En ligne: $conducteursEnLigne',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Barre de progression pour conducteurs hors ligne
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: totalConducteurs > 0 
                            ? ((totalConducteurs - conducteursEnLigne) / totalConducteurs) * 300 // Utilisation de la largeur fixe
                            : 0,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      Center(
                        child: Text(
                          'Hors ligne: ${totalConducteurs - conducteursEnLigne}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Statistiques textuelles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          totalConducteurs > 0 
                              ? '${((conducteursEnLigne / totalConducteurs) * 100).toStringAsFixed(1)}%' 
                              : '0.0%',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'En ligne',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          totalConducteurs > 0 
                              ? '${(((totalConducteurs - conducteursEnLigne) / totalConducteurs) * 100).toStringAsFixed(1)}%' 
                              : '0.0%',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'Hors ligne',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FC),
          drawer: isMobile ? AdminMenu() : null,
          body: Row(
            children: [
              if (!isMobile) AdminMenu(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Trajets en Temps Réel",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF002244),
                            ),
                          ),
                          IconButton(
                            onPressed: loadData,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Actualiser',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Gestion des erreurs
                      if (errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red.shade600),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => errorMessage = null),
                                icon: Icon(Icons.close, color: Colors.red.shade600),
                              ),
                            ],
                          ),
                        ),

                      // Contenu principal
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Panneau gauche - Conducteurs et trajets
                                  Column(
                                    children: [
                                      Expanded(
                                        child: _buildConducteursList(),
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: _buildTrajetsList(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Panneau central - Carte
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: GoogleMap(
                                          initialCameraPosition: CameraPosition(
                                            target: centerPosition ?? const LatLng(AppConfig.defaultLatitude, AppConfig.defaultLongitude),
                                            zoom: AppConfig.defaultZoom,
                                          ),
                                          markers: markers,
                                          polylines: polylines,
                                          onMapCreated: (GoogleMapController controller) {
                                            mapController = controller;
                                          },
                                          mapType: MapType.normal,
                                          myLocationEnabled: true,
                                          myLocationButtonEnabled: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Panneau droit - Statistiques et graphiques
                                  Column(
                                    children: [
                                      _buildStatsCards(),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: _buildChart(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
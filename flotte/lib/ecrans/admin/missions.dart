import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flotte/widgets/menu_admin/admin_menu.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class MissionsPage extends StatefulWidget {
  const MissionsPage({super.key});

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  String searchQuery = '';
  String selectedStatut = 'Tous';
  final List<String> statuts = ['Tous', 'En attente', 'Acceptée', 'Refusée', 'En cours', 'Terminée', 'Planifiée'];
  List<dynamic> missions = [];
  bool isLoading = true;
  String? errorMessage;
  List<dynamic> vehicles = [];
  List<dynamic> drivers = [];

  @override
  void initState() {
    super.initState();
    loadData();
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

      // Charger les missions
      final missionsResponse = await http.get(
        Uri.parse('http://192.168.11.243:8000/api/missions/'),
        headers: headers,
      );

      if (missionsResponse.statusCode == 200) {
        final data = json.decode(missionsResponse.body);
        missions = data is List ? data : (data['results'] ?? []);
      }

      // Charger les véhicules
      final vehiclesResponse = await http.get(
        Uri.parse('http://192.168.11.243:8000/api/vehicles/'),
        headers: headers,
      );

      if (vehiclesResponse.statusCode == 200) {
        final data = json.decode(vehiclesResponse.body);
        vehicles = data is List ? data : (data['results'] ?? []);
      }

      // Charger les conducteurs
      final driversResponse = await http.get(
        Uri.parse('http://192.168.11.243:8000/api/drivers/'),
        headers: headers,
      );

      if (driversResponse.statusCode == 200) {
        final data = json.decode(driversResponse.body);
        drivers = data is List ? data : (data['results'] ?? []);
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de connexion: $e';
        isLoading = false;
      });
      print("Erreur récupération missions: $e");
    }
  }

  Future<void> createMission(Map<String, dynamic> missionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.post(
        Uri.parse('http://192.168.11.243:8000/api/missions/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(missionData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission créée avec succès')),
        );
        loadData();
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${error['detail'] ?? 'Erreur inconnue'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> updateMission(int id, Map<String, dynamic> missionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.put(
        Uri.parse('http://192.168.11.243:8000/api/missions/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(missionData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission modifiée avec succès')),
        );
        loadData();
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${error['detail'] ?? 'Erreur inconnue'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> deleteMission(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.delete(
        Uri.parse('http://192.168.11.243:8000/api/missions/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission supprimée avec succès')),
        );
        loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  List<dynamic> get filteredMissions {
    return missions.where((mission) {
      final matchesSearch = 
        mission['code']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
        mission['raison']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
        mission['lieu_depart']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
        mission['lieu_arrivee']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true;
      
      final matchesStatut = selectedStatut == 'Tous' || 
                           mission['statut']?.toString().toLowerCase() == selectedStatut.toLowerCase().replaceAll(' ', '_');
      
      return matchesSearch && matchesStatut;
    }).toList()
    ..sort((a, b) {
      // Trier du plus ancien au plus récent
      final dateA = DateTime.tryParse(a['date_depart'] ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['date_depart'] ?? '') ?? DateTime(1970);
      return dateA.compareTo(dateB);
    });
  }

  void _openMissionDialog({Map<String, dynamic>? mission}) {
    final TextEditingController raisonCtrl =
        TextEditingController(text: mission?['raison'] ?? '');
    final TextEditingController lieuDepartCtrl =
        TextEditingController(text: mission?['lieu_depart'] ?? '');
    final TextEditingController lieuArriveeCtrl =
        TextEditingController(text: mission?['lieu_arrivee'] ?? '');
    final TextEditingController distanceCtrl =
        TextEditingController(text: mission?['distance_km']?.toString() ?? '');
    
    // Variables pour éviter les calculs multiples
    bool isCalculating = false;
    
    // Fonction pour calculer automatiquement la distance avec délai
    void scheduleDistanceCalculation() {
      if (isCalculating) return;
      
      Future.delayed(const Duration(milliseconds: 1000), () async {
        if (lieuDepartCtrl.text.isNotEmpty && 
            lieuArriveeCtrl.text.isNotEmpty && 
            lieuDepartCtrl.text.length > 2 && 
            lieuArriveeCtrl.text.length > 2) {
          isCalculating = true;
          await _calculateAndUpdateDistance(lieuDepartCtrl.text, lieuArriveeCtrl.text, distanceCtrl);
          isCalculating = false;
        }
      });
    }
    
    int? selectedVehicleId = mission?['vehicle'];
    int? selectedDriverId = mission?['driver'];
    String selectedStatut = mission?['statut'] ?? 'en_attente';
    
    DateTime? dateDepart = mission?['date_depart'] != null 
        ? DateTime.tryParse(mission!['date_depart']) 
        : DateTime.now();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission == null ? 'Nouvelle Mission' : 'Modifier Mission',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                TextField(
                  controller: raisonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Raison de la mission',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TypeAheadField<String>(
                        textFieldConfiguration: TextFieldConfiguration(
                          controller: lieuDepartCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Lieu de départ',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.location_on),
                          ),
                          onChanged: (value) {
                            scheduleDistanceCalculation();
                          },
                        ),
                        suggestionsCallback: (pattern) async {
                          return await _getLocationSuggestions(pattern);
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            leading: const Icon(Icons.location_on, size: 20),
                            title: Text(suggestion),
                            dense: true,
                          );
                        },
                        onSuggestionSelected: (suggestion) {
                          lieuDepartCtrl.text = suggestion;
                          scheduleDistanceCalculation();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TypeAheadField<String>(
                        textFieldConfiguration: TextFieldConfiguration(
                          controller: lieuArriveeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Lieu d\'arrivée',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.location_on),
                          ),
                          onChanged: (value) {
                            scheduleDistanceCalculation();
                          },
                        ),
                        suggestionsCallback: (pattern) async {
                          return await _getLocationSuggestions(pattern);
                        },
                        itemBuilder: (context, suggestion) {
                          return ListTile(
                            leading: const Icon(Icons.location_on, size: 20),
                            title: Text(suggestion),
                            dense: true,
                          );
                        },
                        onSuggestionSelected: (suggestion) {
                          lieuArriveeCtrl.text = suggestion;
                          scheduleDistanceCalculation();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          border: Border.all(color: Colors.blue[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.straighten, color: Colors.blue[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Distance',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    distanceCtrl.text.isNotEmpty 
                                        ? '${distanceCtrl.text} km'
                                        : 'Non calculée',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: distanceCtrl.text.isNotEmpty ? Colors.blue[700] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () {
                                if (lieuDepartCtrl.text.isNotEmpty && lieuArriveeCtrl.text.isNotEmpty) {
                                  _calculateAndUpdateDistance(lieuDepartCtrl.text, lieuArriveeCtrl.text, distanceCtrl);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Veuillez saisir les lieux de départ et d\'arrivée')),
                                  );
                                }
                              },
                              tooltip: 'Recalculer la distance',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ListTile(
                        title: const Text('Date de départ'),
                        subtitle: Text(dateDepart != null ? DateFormat('dd/MM/yyyy HH:mm').format(dateDepart!) : 'Non définie'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dateDepart,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: dateDepart != null ? TimeOfDay.fromDateTime(dateDepart!) : TimeOfDay.now(),
                            );
                            if (time != null) {
                              dateDepart = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                              setState(() {});
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedVehicleId,
                        decoration: const InputDecoration(
                          labelText: 'Véhicule',
                          border: OutlineInputBorder(),
                        ),
                        items: vehicles.map((vehicle) {
                          return DropdownMenuItem<int>(
                            value: vehicle['id'] as int,
                            child: Text('${vehicle['marque']} ${vehicle['modele']} - ${vehicle['immatriculation']}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedVehicleId = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: selectedDriverId,
                        decoration: const InputDecoration(
                          labelText: 'Conducteur',
                          border: OutlineInputBorder(),
                        ),
                        items: drivers.map((driver) {
                          return DropdownMenuItem<int>(
                            value: driver['id'] as int,
                            child: Text(driver['user_profile']?['user']?['username'] ?? 'Inconnu'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedDriverId = value;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (mission != null) // Statut seulement pour la modification
                  DropdownButtonFormField<String>(
                    value: selectedStatut,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'en_attente',
                      'acceptee',
                      'refusee',
                      'en_cours',
                      'terminee',
                      'planifiee',
                    ].map((statut) {
                      return DropdownMenuItem(
                        value: statut,
                        child: Text(_getStatutLabel(statut)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedStatut = value!;
                    },
                  ),
                
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (selectedVehicleId == null || selectedDriverId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez sélectionner un véhicule et un conducteur')),
                          );
                          return;
                        }

                        final missionData = {
                          'vehicle': selectedVehicleId,
                          'driver': selectedDriverId,
                          'raison': raisonCtrl.text,
                          'lieu_depart': lieuDepartCtrl.text,
                          'lieu_arrivee': lieuArriveeCtrl.text,
                          'distance_km': double.tryParse(distanceCtrl.text) ?? 0.0,
                          'date_depart': dateDepart?.toIso8601String() ?? DateTime.now().toIso8601String(),
                          'statut': selectedStatut,
                        };

                        if (mission == null) {
                          await createMission(missionData);
                        } else {
                          await updateMission(mission['id'], missionData);
                        }
                        
                        Navigator.pop(context);
                      },
                      child: Text(mission == null ? 'Créer' : 'Modifier'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'en_attente': return 'En attente';
      case 'acceptee': return 'Acceptée';
      case 'refusee': return 'Refusée';
      case 'en_cours': return 'En cours';
      case 'terminee': return 'Terminée';
      case 'planifiee': return 'Planifiée';
      default: return statut;
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'en_attente': return Colors.orange;
      case 'acceptee': return Colors.green;
      case 'refusee': return Colors.red;
      case 'en_cours': return Colors.blue;
      case 'terminee': return Colors.grey;
      case 'planifiee': return Colors.purple;
      default: return Colors.grey;
    }
  }

  Future<void> _openGoogleMaps(String lieuDepart, String lieuArrivee) async {
    final String encodedDepart = Uri.encodeComponent(lieuDepart);
    final String encodedArrivee = Uri.encodeComponent(lieuArrivee);
    final String googleMapsUrl = 'https://www.google.com/maps/dir/$encodedDepart/$encodedArrivee';
    
    final Uri uri = Uri.parse(googleMapsUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir Google Maps')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<List<String>> _getLocationSuggestions(String query) async {
    if (query.length < 2) return [];
    
    try {
      // Utiliser geocoding pour obtenir des suggestions plus rapides
      List<Location> locations = await locationFromAddress(query);
      List<String> suggestions = [];
      
      // Limiter à 3 résultats pour des performances optimales
      for (Location location in locations.take(3)) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude, 
            location.longitude
          );
          
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;
            String suggestion = '';
            
            // Construire l'adresse de manière plus intelligente
            if (place.street != null && place.street!.isNotEmpty) {
              suggestion += place.street!;
            }
            if (place.locality != null && place.locality!.isNotEmpty) {
              if (suggestion.isNotEmpty) suggestion += ', ';
              suggestion += place.locality!;
            }
            if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
              if (suggestion.isNotEmpty) suggestion += ', ';
              suggestion += place.administrativeArea!;
            }
            if (place.country != null && place.country!.isNotEmpty && place.country != 'France') {
              if (suggestion.isNotEmpty) suggestion += ', ';
              suggestion += place.country!;
            }
            
            if (suggestion.isNotEmpty && !suggestions.contains(suggestion)) {
              suggestions.add(suggestion);
            }
          }
        } catch (e) {
          // Continuer avec les autres locations si une échoue
          continue;
        }
      }
      
      // Ajouter des suggestions génériques si pas assez de résultats
      if (suggestions.length < 3) {
        List<String> genericSuggestions = [
          'Paris, France',
          'Lyon, France', 
          'Marseille, France',
          'Toulouse, France',
          'Nice, France',
          'Nantes, France',
          'Strasbourg, France',
          'Montpellier, France',
          'Bordeaux, France',
          'Lille, France'
        ];
        
        for (String generic in genericSuggestions) {
          if (generic.toLowerCase().contains(query.toLowerCase()) && 
              !suggestions.contains(generic) && 
              suggestions.length < 5) {
            suggestions.add(generic);
          }
        }
      }
      
      return suggestions.take(5).toList();
    } catch (e) {
      print('Erreur autocomplétion: $e');
      // Retourner des suggestions de base en cas d'erreur
      return [
        'Paris, France',
        'Lyon, France',
        'Marseille, France'
      ].where((s) => s.toLowerCase().contains(query.toLowerCase())).take(3).toList();
    }
  }

  Future<double> _calculateDistance(String lieuDepart, String lieuArrivee) async {
    try {
      List<Location> departLocations = await locationFromAddress(lieuDepart);
      List<Location> arriveeLocations = await locationFromAddress(lieuArrivee);
      
      if (departLocations.isEmpty || arriveeLocations.isEmpty) {
        return 0.0;
      }
      
      Location depart = departLocations.first;
      Location arrivee = arriveeLocations.first;
      
      double distance = Geolocator.distanceBetween(
        depart.latitude,
        depart.longitude,
        arrivee.latitude,
        arrivee.longitude,
      );
      
      // Convertir en kilomètres
      return distance / 1000;
    } catch (e) {
      print('Erreur calcul distance: $e');
      return 0.0;
    }
  }

  Future<void> _calculateAndUpdateDistance(String lieuDepart, String lieuArrivee, TextEditingController distanceCtrl) async {
    if (lieuDepart.isEmpty || lieuArrivee.isEmpty) return;
    
    // Mettre à jour l'affichage immédiatement
    distanceCtrl.text = 'Calcul...';
    
    try {
      double distance = await _calculateDistance(lieuDepart, lieuArrivee);
      if (distance > 0) {
        distanceCtrl.text = distance.toStringAsFixed(1);
        // Forcer la mise à jour de l'interface
        if (mounted) {
          setState(() {});
        }
      } else {
        distanceCtrl.text = '';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de calculer la distance. Vérifiez les adresses.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      distanceCtrl.text = '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du calcul: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    final driver = mission['driver_details'];
    final vehicle = mission['vehicle_details'];
    final statut = mission['statut'] ?? 'en_attente';
    final statutColor = _getStatutColor(statut);
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec code et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Mission ${mission['code'] ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF002244),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statutColor, width: 1),
                  ),
                  child: Text(
                    _getStatutLabel(statut),
                    style: TextStyle(
                      color: statutColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Informations du conducteur
            if (driver != null) ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF002244).withOpacity(0.1),
                    backgroundImage: driver['user_profile']?['photo'] != null 
                        ? NetworkImage(driver['user_profile']['photo'])
                        : null,
                    child: driver['user_profile']?['photo'] == null
                        ? Icon(Icons.person, color: const Color(0xFF002244), size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver['user_profile']?['user']?['first_name'] != null && 
                          driver['user_profile']?['user']?['last_name'] != null
                              ? '${driver['user_profile']['user']['first_name']} ${driver['user_profile']['user']['last_name']}'
                              : driver['user_profile']?['user']?['username'] ?? 'Inconnu',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF002244),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (driver['user_profile']?['telephone'] != null)
                          Text(
                            driver['user_profile']['telephone'],
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Informations du véhicule
            if (vehicle != null) ...[
              Row(
                children: [
                  Icon(Icons.directions_car, color: const Color(0xFF002244), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${vehicle['marque']} ${vehicle['modele']} - ${vehicle['immatriculation']}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002244),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Trajet
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route, color: Colors.blue[700], size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Trajet',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mission['lieu_depart'] ?? 'Non défini',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF002244),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: Colors.blue[700], size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mission['lieu_arrivee'] ?? 'Non défini',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF002244),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (mission['distance_km'] != null && mission['distance_km'] > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.straighten, color: Colors.blue[700], size: 12),
                        const SizedBox(width: 2),
                        Text(
                          '${mission['distance_km'].toStringAsFixed(1)} km',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Informations supplémentaires
            if (mission['date_depart'] != null) ...[
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.grey[600], size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(mission['date_depart'])),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            
            if (mission['raison'] != null) ...[
              Row(
                children: [
                  Icon(Icons.description, color: Colors.grey[600], size: 12),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      mission['raison'],
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (mission['lieu_depart'] != null && mission['lieu_arrivee'] != null) {
                        _openGoogleMaps(mission['lieu_depart'], mission['lieu_arrivee']);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lieux de départ et d\'arrivée requis pour l\'itinéraire')),
                        );
                      }
                    },
                    icon: const Icon(Icons.directions, size: 14),
                    label: const Text('Itinéraire', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMissionDialog(mission: mission),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Modifier', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF002244),
                      side: const BorderSide(color: Color(0xFF002244)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmer la suppression'),
                        content: const Text('Êtes-vous sûr de vouloir supprimer cette mission ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () {
                              deleteMission(mission['id']);
                              Navigator.pop(context);
                            },
                            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ],
        ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Gestion des Missions",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF002244),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openMissionDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Nouvelle Mission'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF002244),
                              foregroundColor: Colors.white,
                            ),
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

                      // Filtres
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Rechercher une mission...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: selectedStatut,
                            items: statuts.map((statut) {
                              return DropdownMenuItem(
                                value: statut,
                                child: Text(statut),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedStatut = value!;
                              });
                            },
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: loadData,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Actualiser',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Liste des missions avec cartes
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : filteredMissions.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.assignment_outlined,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Aucune mission trouvée',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Créez votre première mission pour commencer',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isMobile ? 1 : (constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : 2)),
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: isMobile ? 1.1 : 0.75,
                                    ),
                                    itemCount: filteredMissions.length,
                                    itemBuilder: (context, index) {
                                      final mission = filteredMissions[index];
                                      return _buildMissionCard(mission);
                                    },
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flotte/widgets/menu_admin/admin_menu.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flotte/config.dart';
import 'package:dio/dio.dart';
import '../../services/http_client.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


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

  // Coordonnées résolues via Google Places
  Map<String, double>? _departCoords; // {lat, lng}
  Map<String, double>? _arriveeCoords;

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
        errorMessage = 'Erreur de connexion au serveur. Vérifiez votre connexion réseau.';
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
        Uri.parse('${AppConfig.baseUrl}/api/missions/'),
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
        SnackBar(content: Text('Erreur réseau: $e')),
      );
    }
  }

  Future<void> updateMission(int id, Map<String, dynamic> missionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/api/missions/$id/'),
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
        SnackBar(content: Text('Erreur réseau: $e')),
      );
    }
  }

  Future<void> deleteMission(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/api/missions/$id/'),
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
        SnackBar(content: Text('Erreur réseau: $e')),
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
      final dateA = DateTime.tryParse(a['date_depart'] ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['date_depart'] ?? '') ?? DateTime(1970);
      return dateA.compareTo(dateB);
    });
  }

  void _openMissionDialog({Map<String, dynamic>? mission}) {
    final TextEditingController raisonCtrl = TextEditingController(text: mission?['raison'] ?? '');
    final TextEditingController lieuDepartCtrl = TextEditingController(text: mission?['lieu_depart'] ?? '');
    final TextEditingController lieuArriveeCtrl = TextEditingController(text: mission?['lieu_arrivee'] ?? '');
    final TextEditingController distanceCtrl = TextEditingController(text: mission?['distance_km']?.toString() ?? '');
    bool isCalculating = false;

    void scheduleDistanceCalculation() {
      if (isCalculating) return;
      Future.delayed(const Duration(milliseconds: 1500), () async {
        if (lieuDepartCtrl.text.isNotEmpty && lieuArriveeCtrl.text.isNotEmpty && lieuDepartCtrl.text.length > 3 && lieuArriveeCtrl.text.length > 3) {
          isCalculating = true;
          try {
            await _calculateAndUpdateDistance(lieuDepartCtrl.text, lieuArriveeCtrl.text, distanceCtrl);
          } catch (e) {
            print('Erreur lors du calcul de distance: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erreur lors du calcul de la distance. Vérifiez votre connexion réseau ou la clé API.')),
            );
          } finally {
            isCalculating = false;
          }
        }
      });
    }

    int? selectedVehicleId = mission?['vehicle'] as int?;
    int? selectedDriverId = mission?['driver'] as int?;
    String selectedStatut = mission?['statut'] ?? 'en_attente';
    DateTime? dateDepart = mission?['date_depart'] != null ? DateTime.tryParse(mission!['date_depart']) : DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 400;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission == null ? 'Nouvelle Mission' : 'Modifier Mission',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: raisonCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Raison de la mission',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                  ),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 12),
                              isSmallScreen
                                  ? Column(
                                      children: [
                                        TypeAheadField<String>(
                                          textFieldConfiguration: TextFieldConfiguration(
                                            controller: lieuDepartCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Lieu de départ',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                              ),
                                              suffixIcon: Icon(Icons.location_on),
                                            ),
                                            onChanged: (value) {
                                              if (value.length > 3) {
                                                scheduleDistanceCalculation();
                                              }
                                            },
                                          ),
                                          suggestionsCallback: (pattern) async {
                                            if (pattern.length < 3) return [];
                                            try {
                                              return await _getLocationSuggestions(pattern);
                                            } catch (e) {
                                              print('Erreur suggestions lieu départ: $e');
                                              return [];
                                            }
                                          },
                                          itemBuilder: (context, suggestion) {
                                            return ListTile(
                                              leading: const Icon(Icons.location_on, size: 20, color: Colors.blue),
                                              title: Text(
                                                suggestion,
                                                style: const TextStyle(fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              dense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                            );
                                          },
                                          onSuggestionSelected: (suggestion) async {
                                            lieuDepartCtrl.text = suggestion;
                                            _departCoords = await _resolvePlaceToLatLng(suggestion);
                                            scheduleDistanceCalculation();
                                          },
                                          noItemsFoundBuilder: (context) => const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Text('Aucun lieu trouvé'),
                                          ),
                                          loadingBuilder: (context) => const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                                SizedBox(width: 8),
                                                Text('Recherche en cours...'),
                                              ],
                                            ),
                                          ),
                                          hideOnLoading: false,
                                          hideOnEmpty: false,
                                          minCharsForSuggestions: 3,
                                          debounceDuration: const Duration(milliseconds: 500),
                                        ),
                                        const SizedBox(height: 12),
                                        TypeAheadField<String>(
                                          textFieldConfiguration: TextFieldConfiguration(
                                            controller: lieuArriveeCtrl,
                                            decoration: const InputDecoration(
                                              labelText: 'Lieu d\'arrivée',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(Radius.circular(8)),
                                              ),
                                              suffixIcon: Icon(Icons.location_on),
                                            ),
                                            onChanged: (value) {
                                              if (value.length > 3) {
                                                scheduleDistanceCalculation();
                                              }
                                            },
                                          ),
                                          suggestionsCallback: (pattern) async {
                                            if (pattern.length < 3) return [];
                                            try {
                                              return await _getLocationSuggestions(pattern);
                                            } catch (e) {
                                              print('Erreur suggestions lieu arrivée: $e');
                                              return [];
                                            }
                                          },
                                          itemBuilder: (context, suggestion) {
                                            return ListTile(
                                              leading: const Icon(Icons.location_on, size: 20, color: Colors.blue),
                                              title: Text(
                                                suggestion,
                                                style: const TextStyle(fontSize: 14),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              dense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                            );
                                          },
                                          onSuggestionSelected: (suggestion) async {
                                            lieuArriveeCtrl.text = suggestion;
                                            _arriveeCoords = await _resolvePlaceToLatLng(suggestion);
                                            scheduleDistanceCalculation();
                                          },
                                          noItemsFoundBuilder: (context) => const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Text('Aucun lieu trouvé'),
                                          ),
                                          loadingBuilder: (context) => const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                                SizedBox(width: 8),
                                                Text('Recherche en cours...'),
                                              ],
                                            ),
                                          ),
                                          hideOnLoading: false,
                                          hideOnEmpty: false,
                                          minCharsForSuggestions: 3,
                                          debounceDuration: const Duration(milliseconds: 500),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: TypeAheadField<String>(
                                            textFieldConfiguration: TextFieldConfiguration(
                                              controller: lieuDepartCtrl,
                                              decoration: const InputDecoration(
                                                labelText: 'Lieu de départ',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                                ),
                                                suffixIcon: Icon(Icons.location_on),
                                              ),
                                              onChanged: (value) {
                                                if (value.length > 3) {
                                                  scheduleDistanceCalculation();
                                                }
                                              },
                                            ),
                                            suggestionsCallback: (pattern) async {
                                              if (pattern.length < 3) return [];
                                              try {
                                                return await _getLocationSuggestions(pattern);
                                              } catch (e) {
                                                print('Erreur suggestions lieu départ: $e');
                                                return [];
                                              }
                                            },
                                            itemBuilder: (context, suggestion) {
                                              return ListTile(
                                                leading: const Icon(Icons.location_on, size: 20, color: Colors.blue),
                                                title: Text(
                                                  suggestion,
                                                  style: const TextStyle(fontSize: 14),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                dense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                              );
                                            },
                                            onSuggestionSelected: (suggestion) async {
                                              lieuDepartCtrl.text = suggestion;
                                              _departCoords = await _resolvePlaceToLatLng(suggestion);
                                              scheduleDistanceCalculation();
                                            },
                                            noItemsFoundBuilder: (context) => const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Text('Aucun lieu trouvé'),
                                            ),
                                            loadingBuilder: (context) => const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Recherche en cours...'),
                                                ],
                                              ),
                                            ),
                                            hideOnLoading: false,
                                            hideOnEmpty: false,
                                            minCharsForSuggestions: 3,
                                            debounceDuration: const Duration(milliseconds: 500),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: TypeAheadField<String>(
                                            textFieldConfiguration: TextFieldConfiguration(
                                              controller: lieuArriveeCtrl,
                                              decoration: const InputDecoration(
                                                labelText: 'Lieu d\'arrivée',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                                ),
                                                suffixIcon: Icon(Icons.location_on),
                                              ),
                                              onChanged: (value) {
                                                if (value.length > 3) {
                                                  scheduleDistanceCalculation();
                                                }
                                              },
                                            ),
                                            suggestionsCallback: (pattern) async {
                                              if (pattern.length < 3) return [];
                                              try {
                                                return await _getLocationSuggestions(pattern);
                                              } catch (e) {
                                                print('Erreur suggestions lieu arrivée: $e');
                                                return [];
                                              }
                                            },
                                            itemBuilder: (context, suggestion) {
                                              return ListTile(
                                                leading: const Icon(Icons.location_on, size: 20, color: Colors.blue),
                                                title: Text(
                                                  suggestion,
                                                  style: const TextStyle(fontSize: 14),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                dense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                              );
                                            },
                                            onSuggestionSelected: (suggestion) async {
                                              lieuArriveeCtrl.text = suggestion;
                                              _arriveeCoords = await _resolvePlaceToLatLng(suggestion);
                                              scheduleDistanceCalculation();
                                            },
                                            noItemsFoundBuilder: (context) => const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Text('Aucun lieu trouvé'),
                                            ),
                                            loadingBuilder: (context) => const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Recherche en cours...'),
                                                ],
                                              ),
                                            ),
                                            hideOnLoading: false,
                                            hideOnEmpty: false,
                                            minCharsForSuggestions: 3,
                                            debounceDuration: const Duration(milliseconds: 500),
                                          ),
                                        ),
                                      ],
                                    ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        border: Border.all(color: Colors.blue[200]!),
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.straighten, color: Colors.blue[700]),
                                          const SizedBox(width: 8),
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
                                                      ? '${double.tryParse(distanceCtrl.text)?.toStringAsFixed(1) ?? distanceCtrl.text} km'
                                                      : 'Non calculée',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: distanceCtrl.text.isNotEmpty ? Colors.blue[700] : Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isCalculating)
                                            const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          else
                                            IconButton(
                                              icon: const Icon(Icons.refresh),
                                              onPressed: () async {
                                                if (lieuDepartCtrl.text.isNotEmpty && lieuArriveeCtrl.text.isNotEmpty) {
                                                  setDialogState(() {
                                                    isCalculating = true;
                                                  });
                                                  try {
                                                    await _calculateAndUpdateDistance(lieuDepartCtrl.text, lieuArriveeCtrl.text, distanceCtrl);
                                                    setDialogState(() {});
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Erreur: $e')),
                                                    );
                                                  } finally {
                                                    setDialogState(() {
                                                      isCalculating = false;
                                                    });
                                                  }
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
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: dateDepart ?? DateTime.now(),
                                          firstDate: DateTime.now(),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                        );
                                        if (date != null) {
                                          final time = await showTimePicker(
                                            context: context,
                                            initialTime: dateDepart != null ? TimeOfDay.fromDateTime(dateDepart!) : TimeOfDay.now(),
                                          );
                                          if (time != null) {
                                            setDialogState(() {
                                              dateDepart = DateTime(
                                                date.year,
                                                date.month,
                                                date.day,
                                                time.hour,
                                                time.minute,
                                              );
                                            });
                                          }
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey[400]!),
                                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Date de départ',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              dateDepart != null 
                                                  ? DateFormat('dd/MM/yyyy HH:mm').format(dateDepart!) 
                                                  : 'Non définie',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              isSmallScreen
                                  ? Column(
                                      children: [
                                        DropdownButtonFormField<int>(
                                          value: selectedVehicleId,
                                          decoration: const InputDecoration(
                                            labelText: 'Véhicule',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(8)),
                                            ),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          ),
                                          items: vehicles.map((vehicle) {
                                            String vehicleText = vehicle['marque'] != null && vehicle['modele'] != null && vehicle['immatriculation'] != null
                                                ? '${vehicle['marque']} ${vehicle['modele']} - ${vehicle['immatriculation']}'
                                                : 'Véhicule ${vehicle['id']}';
                                            vehicleText = vehicleText.length > 25 ? '${vehicleText.substring(0, 22)}...' : vehicleText;
                                            return DropdownMenuItem<int>(
                                              value: vehicle['id'] as int?,
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.65),
                                                child: Text(
                                                  vehicleText,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 13),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setDialogState(() {
                                              selectedVehicleId = value;
                                            });
                                          },
                                          isExpanded: true,
                                          isDense: true,
                                          menuMaxHeight: 200,
                                          dropdownColor: Colors.white,
                                        ),
                                        const SizedBox(height: 12),
                                        DropdownButtonFormField<int>(
                                          value: selectedDriverId,
                                          decoration: const InputDecoration(
                                            labelText: 'Conducteur',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(8)),
                                            ),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                          ),
                                          items: drivers.map((driver) {
                                            String driverName = 'Conducteur ${driver['id']}';
                                            if (driver != null) {
                                              if (driver['user_profile'] != null) {
                                                if (driver['user_profile']['user'] != null) {
                                                  driverName = driver['user_profile']['user']['username'] ??
                                                      driver['user_profile']['user']['first_name'] ??
                                                      driver['user_profile']['user']['last_name'] ??
                                                      '${driver['user_profile']['user']['first_name'] ?? ''} ${driver['user_profile']['user']['last_name'] ?? ''}'.trim();
                                                } else {
                                                  driverName = driver['user_profile']['username'] ??
                                                      driver['user_profile']['first_name'] ??
                                                      driver['user_profile']['last_name'] ??
                                                      '${driver['user_profile']['first_name'] ?? ''} ${driver['user_profile']['last_name'] ?? ''}'.trim();
                                                }
                                              } else if (driver['user'] != null) {
                                                driverName = driver['user']['username'] ??
                                                    driver['user']['first_name'] ??
                                                    driver['user']['last_name'] ??
                                                    '${driver['user']['first_name'] ?? ''} ${driver['user']['last_name'] ?? ''}'.trim();
                                              }
                                            }
                                            if (driverName.isEmpty) {
                                              driverName = 'Conducteur ${driver['id']}';
                                            }
                                            driverName = driverName.length > 25 ? '${driverName.substring(0, 22)}...' : driverName;
                                            return DropdownMenuItem<int>(
                                              value: driver['id'] as int?,
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.65),
                                                child: Text(
                                                  driverName,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 13),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setDialogState(() {
                                              selectedDriverId = value;
                                            });
                                          },
                                          isExpanded: true,
                                          isDense: true,
                                          menuMaxHeight: 200,
                                          dropdownColor: Colors.white,
                                        ),
                                      ],
                                    )
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          ConstrainedBox(
                                            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.45),
                                            child: DropdownButtonFormField<int>(
                                              value: selectedVehicleId,
                                              decoration: const InputDecoration(
                                                labelText: 'Véhicule',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                                ),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              ),
                                              items: vehicles.map((vehicle) {
                                                String vehicleText = vehicle['marque'] != null && vehicle['modele'] != null && vehicle['immatriculation'] != null
                                                    ? '${vehicle['marque']} ${vehicle['modele']} - ${vehicle['immatriculation']}'
                                                    : 'Véhicule ${vehicle['id']}';
                                                vehicleText = vehicleText.length > 25 ? '${vehicleText.substring(0, 22)}...' : vehicleText;
                                                return DropdownMenuItem<int>(
                                                  value: vehicle['id'] as int?,
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.4),
                                                    child: Text(
                                                      vehicleText,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 13),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setDialogState(() {
                                                  selectedVehicleId = value;
                                                });
                                              },
                                            isExpanded: true,
                                              isDense: true,
                                              menuMaxHeight: 200,
                                              dropdownColor: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ConstrainedBox(
                                            constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.45),
                                            child: DropdownButtonFormField<int>(
                                              value: selectedDriverId,
                                              decoration: const InputDecoration(
                                                labelText: 'Conducteur',
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                                ),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              ),
                                              items: drivers.map((driver) {
                                                String driverName = 'Conducteur ${driver['id']}';
                                                if (driver != null) {
                                                  if (driver['user_profile'] != null) {
                                                    if (driver['user_profile']['user'] != null) {
                                                      driverName = driver['user_profile']['user']['username'] ??
                                                          driver['user_profile']['user']['first_name'] ??
                                                          driver['user_profile']['user']['last_name'] ??
                                                          '${driver['user_profile']['user']['first_name'] ?? ''} ${driver['user_profile']['user']['last_name'] ?? ''}'.trim();
                                                    } else {
                                                      driverName = driver['user_profile']['username'] ??
                                                          driver['user_profile']['first_name'] ??
                                                          driver['user_profile']['last_name'] ??
                                                          '${driver['user_profile']['first_name'] ?? ''} ${driver['user_profile']['last_name'] ?? ''}'.trim();
                                                    }
                                                  } else if (driver['user'] != null) {
                                                    driverName = driver['user']['username'] ??
                                                        driver['user']['first_name'] ??
                                                        driver['user']['last_name'] ??
                                                        '${driver['user']['first_name'] ?? ''} ${driver['user']['last_name'] ?? ''}'.trim();
                                                  }
                                                }
                                                if (driverName.isEmpty) {
                                                  driverName = 'Conducteur ${driver['id']}';
                                                }
                                                driverName = driverName.length > 25 ? '${driverName.substring(0, 22)}...' : driverName;
                                                return DropdownMenuItem<int>(
                                                  value: driver['id'] as int?,
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.4),
                                                    child: Text(
                                                      driverName,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontSize: 13),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setDialogState(() {
                                                  selectedDriverId = value;
                                                });
                                              },
                                          isExpanded: true,
                                              isDense: true,
                                              menuMaxHeight: 200,
                                              dropdownColor: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                              const SizedBox(height: 12),
                              if (mission != null)
                                DropdownButtonFormField<String>(
                                  value: selectedStatut,
                                  decoration: const InputDecoration(
                                    labelText: 'Statut',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(8)),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                                      child: Text(
                                        _getStatutLabel(statut),
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      selectedStatut = value!;
                                    });
                                  },
                                  isExpanded: true,
                                  isDense: true,
                                  menuMaxHeight: 200,
                                  dropdownColor: Colors.white,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                                if (_departCoords != null) 'depart_latitude': _departCoords!['lat'],
                                if (_departCoords != null) 'depart_longitude': _departCoords!['lng'],
                                if (_arriveeCoords != null) 'arrivee_latitude': _arriveeCoords!['lat'],
                                if (_arriveeCoords != null) 'arrivee_longitude': _arriveeCoords!['lng'],
                              };

                              try {
                                if (mission == null) {
                                  await createMission(missionData);
                                } else {
                                  await updateMission(mission['id'] as int, missionData);
                                }
                                Navigator.pop(context);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Erreur réseau: $e')),
                                );
                              }
                            },
                            child: Text(mission == null ? 'Créer' : 'Modifier'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
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
        SnackBar(content: Text('Erreur réseau: $e')),
      );
    }
  }

  Future<List<String>> _getLocationSuggestions(String query) async {
    print('Appel API Google Places pour suggestions avec query: $query');
    print('Clé API utilisée: ${AppConfig.googleMapsApiKey}');
    if (query.length < 2) return [];

    try {
      final dio = HttpClient.instance;
      final response = await dio.get('/api/places/autocomplete/', queryParameters: {
        'input': query,
        'language': 'fr',
        'components': 'country:ci|country:fr',
        'types': 'geocode',
      });
      print('Réponse API Places: Statut ${response.statusCode}, Données: ${response.data}');
      if (response.statusCode == 200) {
        final List preds = (response.data['predictions'] as List? ?? []);
        return preds.map((p) => p['description'] as String).cast<String>().take(6).toList();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur API Places: Statut ${response.statusCode}')),
      );
      return [];
    } catch (e) {
      print('Erreur autocomplétion Google Places: $e');
      if (e is DioException) {
        print('Détails DioException: Type=${e.type}, Message=${e.message}, Réponse=${e.response?.data}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur réseau lors de la récupération des suggestions de lieu.')),
      );
      return [];
    }
  }

  Future<double> _calculateDistance(String lieuDepart, String lieuArrivee) async {
    print('Calcul de distance entre "$lieuDepart" et "$lieuArrivee"');
    print('Clé API utilisée: ${AppConfig.googleMapsApiKey}');
    try {
      final dio = HttpClient.instance;
      final response = await dio.get('/api/places/distance/', queryParameters: {
        'origins': lieuDepart,
        'destinations': lieuArrivee,
        'language': 'fr',
        'units': 'metric',
      });
      print('Réponse API Distance Matrix: Statut ${response.statusCode}, Données: ${response.data}');
      if (response.statusCode == 200) {
        final rows = response.data['rows'] as List?;
        if (rows != null && rows.isNotEmpty) {
          final elements = rows.first['elements'] as List?;
          if (elements != null && elements.isNotEmpty && elements.first['status'] == 'OK') {
            final meters = elements.first['distance']?['value'] as int?;
            if (meters != null) {
              return meters / 1000.0;
            }
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de calculer la distance. Vérifiez les adresses.')),
        );
        return 0.0;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur API Distance Matrix: Statut ${response.statusCode}')),
        );
        return 0.0;
      }
    } catch (e) {
      print('Erreur calcul distance (Distance Matrix): $e');
      if (e is DioException) {
        print('Détails DioException: Type=${e.type}, Message=${e.message}, Réponse=${e.response?.data}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur réseau lors du calcul de la distance.')),
      );
      return 0.0;
    }
  }

  Future<Map<String, double>?> _resolvePlaceToLatLng(String description) async {
    print('Résolution des coordonnées pour: $description');
    print('Clé API utilisée: ${AppConfig.googleMapsApiKey}');
    try {
      final dio = HttpClient.instance;
      final ac = await dio.get('/api/places/autocomplete/', queryParameters: {
        'input': description,
        'language': 'fr',
      });
      print('Réponse API Autocomplete: Statut ${ac.statusCode}, Données: ${ac.data}');
      final preds = (ac.data['predictions'] as List? ?? []);
      if (preds.isEmpty) return null;
      final placeId = preds.first['place_id'] as String?;
      if (placeId == null) return null;

      final details = await dio.get('/api/places/details/', queryParameters: {
        'place_id': placeId,
        'language': 'fr',
        'fields': 'geometry',
      });
      print('Réponse API Place Details: Statut ${details.statusCode}, Données: ${details.data}');
      final result = details.data['result'];
      final loc = result?['geometry']?['location'];
      if (loc == null) return null;
      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();
      return {'lat': lat, 'lng': lng};
    } catch (e) {
      print('Erreur Place Details: $e');
      if (e is DioException) {
        print('Détails DioException: Type=${e.type}, Message=${e.message}, Réponse=${e.response?.data}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur réseau lors de la résolution des coordonnées.')),
      );
      return null;
    }
  }

  Future<void> _calculateAndUpdateDistance(String lieuDepart, String lieuArrivee, TextEditingController distanceCtrl) async {
    if (lieuDepart.isEmpty || lieuArrivee.isEmpty) return;
    
    distanceCtrl.text = 'Calcul...';
    
    try {
      double distance = await _calculateDistance(lieuDepart, lieuArrivee);
      if (distance > 0) {
        distanceCtrl.text = distance.toStringAsFixed(1);
        if (mounted) {
          setState(() {});
        }
      } else {
        distanceCtrl.text = '';
      }
    } catch (e) {
      distanceCtrl.text = '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réseau lors du calcul: $e'),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
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
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (driver != null) ...[
                      Row(
                        children: [
                          ClipOval(
                            child: driver['user_profile']?['photo'] != null
                                ? Image.network(
                                    driver['user_profile']['photo'],
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 36,
                                      height: 36,
                                      color: const Color(0xFF002244).withOpacity(0.1),
                                      child: const Icon(
                                        Icons.person,
                                        color: Color(0xFF002244),
                                        size: 16,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 36,
                                    height: 36,
                                    color: const Color(0xFF002244).withOpacity(0.1),
                                    child: const Icon(
                                      Icons.person,
                                      color: Color(0xFF002244),
                                      size: 16,
                                    ),
                                  ),
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
                    if (vehicle != null) ...[
                      Row(
                        children: [
                          Icon(Icons.directions_car, color: const Color(0xFF002244), size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${vehicle['marque'] ?? ''} ${vehicle['modele'] ?? ''} - ${vehicle['immatriculation'] ?? ''}'.trim(),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: const BorderRadius.all(Radius.circular(6)),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
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
                          if (mission['distance_km'] != null && (mission['distance_km'] as num) > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.straighten, color: Colors.blue[700], size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  '${(mission['distance_km'] as num).toStringAsFixed(1)} km',
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
                    if (mission['date_depart'] != null) ...[
                      Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.grey[600], size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse(mission['date_depart']) ?? DateTime.now()),
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
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final depart = mission['lieu_depart']?.toString();
                      final arrivee = mission['lieu_arrivee']?.toString();
                      if (depart != null && arrivee != null && depart.isNotEmpty && arrivee.isNotEmpty) {
                        _openGoogleMaps(depart, arrivee);
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
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
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
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
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
                              deleteMission(mission['id'] as int);
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
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
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
          drawer: isMobile ? const AdminMenu() : null,
          body: Row(
            children: [
              if (!isMobile) const AdminMenu(),
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
                      if (errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade200),
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
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
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                              },
                              decoration: const InputDecoration(
                                hintText: 'Rechercher une mission...',
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
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
                                      childAspectRatio: isMobile ? 1.1 : 0.8,
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
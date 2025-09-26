import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flotte/widgets/menu_admin/admin_menu.dart';

class VehiculePage extends StatefulWidget {
  const VehiculePage({super.key});

  @override
  State<VehiculePage> createState() => _VehiculePageState();
}

class _VehiculePageState extends State<VehiculePage> {
  String searchQuery = '';
  String selectedStatut = 'Tous';
  String? selectedTypeCarburant;
  String? selectedTypeVehicule;
  List<dynamic> vehicules = [];
  bool isLoading = true;
  String? errorMessage;

  final List<String> statuts = ['Tous', 'Actif', 'Inactif'];
  final List<String> typesVoiture = [
    'SUV',
    'Berline',
    'Break',
    'Citadine',
    '4x4',
    'Camion',
    'Camionnette',
    'Autres'
  ];
  final List<String> typesCarburant = [
    'essence',
    'diesel',
    'electrique',
    'hybride',
    'autre'
  ];

  @override
  void initState() {
    super.initState();
    fetchVehicules();
  }

  Future<void> fetchVehicules() async {
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

      final response = await http.get(
        Uri.parse('http://192.168.11.243:8000/api/vehicles/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          vehicules = data is List ? data : (data['results'] ?? []);
          isLoading = false;
        });
        debugPrint('Véhicules récupérés: ${vehicules.length}');
      } else {
        setState(() {
          errorMessage = 'Erreur ${response.statusCode}: ${response.reasonPhrase}';
          isLoading = false;
        });
        debugPrint('Erreur récupération véhicules: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de connexion: $e';
        isLoading = false;
      });
      debugPrint('Erreur récupération véhicules: $e');
    }
  }

  Future<void> createVehicule(Map<String, dynamic> vehiculeData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final formattedVehiculeData = Map<String, dynamic>.from(vehiculeData);
      if (vehiculeData['date_acquisition'] != null) {
        formattedVehiculeData['date_acquisition'] =
            DateFormat('yyyy-MM-dd').format(DateTime.parse(vehiculeData['date_acquisition']));
      }
      if (vehiculeData['assurance_expiration'] != null) {
        formattedVehiculeData['assurance_expiration'] =
            DateFormat('yyyy-MM-dd').format(DateTime.parse(vehiculeData['assurance_expiration']));
      }
      if (vehiculeData['visite_technique'] != null) {
        formattedVehiculeData['visite_technique'] =
            DateFormat('yyyy-MM-dd').format(DateTime.parse(vehiculeData['visite_technique']));
      }

      debugPrint('Données envoyées: ${json.encode(formattedVehiculeData)}');

      final response = await http.post(
        Uri.parse('http://192.168.11.243:8000/api/vehicles/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(formattedVehiculeData),
      );

      debugPrint('Réponse API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Véhicule créé avec succès')),
        );
        fetchVehicules();
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${error['detail'] ?? error.toString()}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
      debugPrint('Erreur création véhicule: $e');
    }
  }

  Future<void> updateVehicule(int id, Map<String, dynamic> vehiculeData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final formattedVehiculeData = Map<String, dynamic>.from(vehiculeData);
      if (vehiculeData['date_acquisition'] != null) {
        formattedVehiculeData['date_acquisition'] =
            DateFormat('yyyy-MM-dd').format(DateTime.parse(vehiculeData['date_acquisition']));
      }
      if (vehiculeData['assurance_expiration'] != null) {
        formattedVehiculeData['assurance_expiration'] =
            DateFormat('yyyy-MM-dd').format(DateTime.parse(vehiculeData['assurance_expiration']));
      }
      if (vehiculeData['visite_technique'] != null) {
        formattedVehiculeData['visite_technique'] =
            DateFormat('yyyy-MM-dd').format(DateTime.parse(vehiculeData['visite_technique']));
      }

      debugPrint('Données envoyées: ${json.encode(formattedVehiculeData)}');

      final response = await http.put(
        Uri.parse('http://192.168.11.243:8000/api/vehicles/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(formattedVehiculeData),
      );

      debugPrint('Réponse API: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Véhicule modifié avec succès')),
        );
        fetchVehicules();
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${error['detail'] ?? error.toString()}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
      debugPrint('Erreur mise à jour véhicule: $e');
    }
  }

  Future<void> deleteVehicule(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.delete(
        Uri.parse('http://192.168.11.243:8000/api/vehicles/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Véhicule supprimé avec succès')),
        );
        fetchVehicules();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
      debugPrint('Erreur suppression véhicule: $e');
    }
  }

  List<dynamic> get filteredVehicules {
    return vehicules.where((vehicule) {
      final matchesSearch =
          vehicule['marque']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
          vehicule['modele']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
          vehicule['immatriculation']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
          vehicule['type_carburant']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true;

      final matchesStatut =
          selectedStatut == 'Tous' ||
          (selectedStatut == 'Actif' && vehicule['actif'] == true) ||
          (selectedStatut == 'Inactif' && vehicule['actif'] == false);

      final matchesTypeCarburant = selectedTypeCarburant == null || vehicule['type_carburant'] == selectedTypeCarburant;
      final matchesTypeVehicule = selectedTypeVehicule == null || vehicule['type_vehicule'] == selectedTypeVehicule;

      return matchesSearch && matchesStatut && matchesTypeCarburant && matchesTypeVehicule;
    }).toList();
  }

  void _showVehiculeFormDialog({Map<String, dynamic>? vehicule}) async {
    final TextEditingController marqueCtrl = TextEditingController(text: vehicule?['marque'] ?? '');
    final TextEditingController modeleCtrl = TextEditingController(text: vehicule?['modele'] ?? '');
    String typeVoitureValue = vehicule?['type_vehicule'] ?? typesVoiture.first;
    String typeCarburantValue = vehicule?['type_carburant'] ?? typesCarburant.first;
    final TextEditingController immatriculationCtrl = TextEditingController(text: vehicule?['immatriculation'] ?? '');
    final TextEditingController kilometrageCtrl = TextEditingController(text: vehicule?['kilometrage']?.toString() ?? '');
    final TextEditingController capaciteReservoirCtrl = TextEditingController(text: vehicule?['capacite_reservoir']?.toString() ?? '');
    final TextEditingController couleurCtrl = TextEditingController(text: vehicule?['couleur'] ?? '');
    final TextEditingController prixCtrl = TextEditingController(text: vehicule?['prix_acquisition']?.toString() ?? '');
    final TextEditingController chassisCtrl = TextEditingController(text: vehicule?['numero_chassis'] ?? '');
    bool statutValue = vehicule?['actif'] ?? true;

    DateTime? dateAchat = vehicule?['date_acquisition'] != null
        ? DateTime.tryParse(vehicule!['date_acquisition'])
        : null;
    DateTime? dateAssurance = vehicule?['assurance_expiration'] != null
        ? DateTime.tryParse(vehicule!['assurance_expiration'])
        : null;
    DateTime? dateVisite = vehicule?['visite_technique'] != null
        ? DateTime.tryParse(vehicule!['visite_technique'])
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        vehicule == null ? 'Ajouter un véhicule' : 'Modifier le véhicule',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF002244),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Informations générales',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: marqueCtrl,
                              decoration: InputDecoration(
                                labelText: 'Marque',
                                prefixIcon: const Icon(Icons.directions_car),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF002244)),
                                ),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer la marque' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: modeleCtrl,
                              decoration: InputDecoration(
                                labelText: 'Modèle',
                                prefixIcon: const Icon(Icons.directions_car),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF002244)),
                                ),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer le modèle' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: typeVoitureValue,
                              decoration: InputDecoration(
                                labelText: 'Type de véhicule',
                                prefixIcon: const Icon(Icons.category),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF002244)),
                                ),
                              ),
                              items: typesVoiture.map((type) {
                                return DropdownMenuItem(value: type, child: Text(type));
                              }).toList(),
                              onChanged: (value) => setDialogState(() => typeVoitureValue = value!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: immatriculationCtrl,
                              decoration: InputDecoration(
                                labelText: 'Immatriculation',
                                prefixIcon: const Icon(Icons.confirmation_number),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF002244)),
                                ),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer l\'immatriculation' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Détails techniques',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: typeCarburantValue,
                              decoration: InputDecoration(
                                labelText: 'Type de carburant',
                                prefixIcon: const Icon(Icons.local_gas_station),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF002244)),
                                ),
                              ),
                              items: typesCarburant.map((type) {
                                return DropdownMenuItem(value: type, child: Text(type[0].toUpperCase() + type.substring(1)));
                              }).toList(),
                              onChanged: (value) => setDialogState(() => typeCarburantValue = value!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: kilometrageCtrl,
                              decoration: InputDecoration(
                                labelText: 'Kilométrage (km)',
                                prefixIcon: const Icon(Icons.speed),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF002244)),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value == null || value.isEmpty || double.tryParse(value) == null ? 'Veuillez entrer un kilométrage valide' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: capaciteReservoirCtrl,
                              decoration: InputDecoration(
                                labelText: 'Capacité réservoir (L)',
                                prefixIcon: const Icon(Icons.local_gas_station),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF002244)),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) => value == null || value.isEmpty || double.tryParse(value) == null ? 'Veuillez entrer une capacité valide' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: couleurCtrl,
                              decoration: InputDecoration(
                                labelText: 'Couleur',
                                prefixIcon: const Icon(Icons.color_lens),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF002244)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: prixCtrl,
                              decoration: InputDecoration(
                                labelText: 'Prix d\'acquisition (€)',
                                prefixIcon: const Icon(Icons.euro),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF002244)),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: chassisCtrl,
                              decoration: InputDecoration(
                                labelText: 'Numéro de chassis',
                                prefixIcon: const Icon(Icons.build),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF002244)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Statut et dates',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text('Véhicule actif', style: GoogleFonts.poppins()),
                        value: statutValue,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (value) => setDialogState(() => statutValue = value),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.calendar_today, color: Color(0xFF002244)),
                        title: Text('Date d\'acquisition', style: GoogleFonts.poppins()),
                        subtitle: Text(dateAchat != null ? DateFormat('dd/MM/yyyy').format(dateAchat!) : 'Non définie'),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dateAchat ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setDialogState(() => dateAchat = date);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.calendar_today, color: Color(0xFF002244)),
                        title: Text('Expiration assurance', style: GoogleFonts.poppins()),
                        subtitle: Text(dateAssurance != null ? DateFormat('dd/MM/yyyy').format(dateAssurance!) : 'Non définie'),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dateAssurance ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (date != null) setDialogState(() => dateAssurance = date);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.calendar_today, color: Color(0xFF002244)),
                        title: Text('Visite technique', style: GoogleFonts.poppins()),
                        subtitle: Text(dateVisite != null ? DateFormat('dd/MM/yyyy').format(dateVisite!) : 'Non définie'),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dateVisite ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (date != null) setDialogState(() => dateVisite = date);
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Annuler', style: GoogleFonts.poppins(color: Colors.grey)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () async {
                              if (marqueCtrl.text.isEmpty ||
                                  modeleCtrl.text.isEmpty ||
                                  immatriculationCtrl.text.isEmpty ||
                                  double.tryParse(kilometrageCtrl.text) == null ||
                                  double.tryParse(capaciteReservoirCtrl.text) == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Veuillez remplir tous les champs requis')),
                                );
                                return;
                              }

                              final vehiculeData = {
                                'marque': marqueCtrl.text,
                                'modele': modeleCtrl.text,
                                'type_vehicule': typeVoitureValue,
                                'type_carburant': typeCarburantValue,
                                'immatriculation': immatriculationCtrl.text,
                                'kilometrage': double.parse(kilometrageCtrl.text),
                                'capacite_reservoir': double.parse(capaciteReservoirCtrl.text),
                                'couleur': couleurCtrl.text.isEmpty ? null : couleurCtrl.text,
                                'prix_acquisition': double.tryParse(prixCtrl.text),
                                'numero_chassis': chassisCtrl.text.isEmpty ? null : chassisCtrl.text,
                                'actif': statutValue,
                                'date_acquisition': dateAchat?.toIso8601String(),
                                'assurance_expiration': dateAssurance?.toIso8601String(),
                                'visite_technique': dateVisite?.toIso8601String(),
                              };

                              if (vehicule == null) {
                                await createVehicule(vehiculeData);
                              } else {
                                await updateVehicule(vehicule['id'], vehiculeData);
                              }

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(vehicule == null ? 'Ajouter' : 'Modifier', style: GoogleFonts.poppins()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showVehiculeDetailDialog(Map<String, dynamic> vehicule) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      "${vehicule['marque']} ${vehicule['modele']}",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF002244),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(Icons.directions_car, 'Type', vehicule['type_vehicule']),
                  _buildDetailRow(Icons.local_gas_station, 'Type de carburant', vehicule['type_carburant'] ?? 'Non défini'),
                  _buildDetailRow(Icons.confirmation_number, 'Immatriculation', vehicule['immatriculation']),
                  _buildDetailRow(Icons.speed, 'Kilométrage', '${vehicule['kilometrage']} km'),
                  _buildDetailRow(Icons.local_gas_station, 'Capacité réservoir', '${vehicule['capacite_reservoir']} L'),
                  _buildDetailRow(Icons.color_lens, 'Couleur', vehicule['couleur'] ?? 'Non défini'),
                  _buildDetailRow(Icons.euro, 'Prix d\'acquisition', vehicule['prix_acquisition'] != null ? '${vehicule['prix_acquisition']}€' : 'Non défini'),
                  _buildDetailRow(Icons.build, 'Numéro de chassis', vehicule['numero_chassis'] ?? 'Non défini'),
                  if (vehicule['date_acquisition'] != null)
                    _buildDetailRow(Icons.calendar_today, 'Date d\'acquisition', DateFormat('dd/MM/yyyy').format(DateTime.parse(vehicule['date_acquisition']))),
                  if (vehicule['assurance_expiration'] != null)
                    _buildDetailRow(Icons.calendar_today, 'Expiration assurance', DateFormat('dd/MM/yyyy').format(DateTime.parse(vehicule['assurance_expiration']))),
                  if (vehicule['visite_technique'] != null)
                    _buildDetailRow(Icons.calendar_today, 'Visite technique', DateFormat('dd/MM/yyyy').format(DateTime.parse(vehicule['visite_technique']))),
                  _buildDetailRow(Icons.circle, 'Statut', vehicule['actif'] ? 'Actif' : 'Inactif', statusColor: vehicule['actif'] ? Colors.green : Colors.red),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implémenter le téléchargement PDF
                      },
                      icon: const Icon(Icons.download, size: 20),
                      label: Text('Télécharger la fiche', style: GoogleFonts.poppins()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF002244),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF002244), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
                    if (statusColor != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiculeCard(Map<String, dynamic> vehicule) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showVehiculeDetailDialog(vehicule),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                image: vehicule['photo'] != null
                    ? DecorationImage(
                        image: NetworkImage(vehicule['photo']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: vehicule['photo'] == null
                  ? const Center(child: Icon(Icons.directions_car, size: 32, color: Colors.grey))
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${vehicule['marque']} ${vehicule['modele']}',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: vehicule['actif'] ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Matricule: ${vehicule['immatriculation']}', style: GoogleFonts.poppins(fontSize: 12)),
                  Text('Km: ${vehicule['kilometrage']} km', style: GoogleFonts.poppins(fontSize: 12)),
                  Text('Type: ${vehicule['type_vehicule']}', style: GoogleFonts.poppins(fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye, size: 16, color: Color(0xFF002244)),
                        tooltip: 'Voir',
                        onPressed: () => _showVehiculeDetailDialog(vehicule),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16, color: Color(0xFF10B981)),
                        tooltip: 'Modifier',
                        onPressed: () => _showVehiculeFormDialog(vehicule: vehicule),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                        tooltip: 'Supprimer',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirmer la suppression'),
                              content: Text('Êtes-vous sûr de vouloir supprimer le véhicule ${vehicule['marque']} ${vehicule['modele']} ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Annuler', style: GoogleFonts.poppins()),
                                ),
                                TextButton(
                                  onPressed: () {
                                    deleteVehicule(vehicule['id']);
                                    Navigator.pop(context);
                                  },
                                  child: Text('Supprimer', style: GoogleFonts.poppins(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
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
        final crossAxisCount = isMobile ? 1 : constraints.maxWidth < 1000 ? 3 : 4;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          drawer: isMobile ? const AdminMenu() : null,
          appBar: isMobile
              ? AppBar(
                  title: Text(
                    'Véhicules',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  backgroundColor: const Color(0xFF002244),
                  iconTheme: const IconThemeData(color: Colors.white),
                )
              : null,
          body: Row(
            children: [
              if (!isMobile)
                SizedBox(
                  width: 240,
                  child: const AdminMenu(),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile)
                        Text(
                          'Gestion des Véhicules',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF002244),
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red.shade600),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: GoogleFonts.poppins(color: Colors.red.shade700),
                                ),
                              ),
                              IconButton(
                                onPressed: () => setState(() => errorMessage = null),
                                icon: Icon(Icons.close, color: Colors.red.shade600),
                              ),
                            ],
                          ),
                        ),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 240,
                                child: TextField(
                                  onChanged: (value) => setState(() => searchQuery = value),
                                  decoration: InputDecoration(
                                    labelText: 'Rechercher un véhicule',
                                    hintText: 'Marque, modèle, immatriculation...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF002244)),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: DropdownButtonFormField<String>(
                                  value: selectedStatut,
                                  onChanged: (value) => setState(() => selectedStatut = value!),
                                  decoration: InputDecoration(
                                    labelText: 'Statut',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF002244)),
                                    ),
                                  ),
                                  items: statuts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: DropdownButtonFormField<String>(
                                  value: selectedTypeCarburant,
                                  hint: Text('Type de carburant', style: GoogleFonts.poppins()),
                                  onChanged: (value) => setState(() => selectedTypeCarburant = value),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF002244)),
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('Tous')),
                                    ...typesCarburant.map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1)))),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: DropdownButtonFormField<String>(
                                  value: selectedTypeVehicule,
                                  hint: Text('Type de véhicule', style: GoogleFonts.poppins()),
                                  onChanged: (value) => setState(() => selectedTypeVehicule = value),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF002244)),
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem(value: null, child: Text('Tous')),
                                    ...typesVoiture.map((e) => DropdownMenuItem(value: e, child: Text(e))),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    searchQuery = '';
                                    selectedStatut = 'Tous';
                                    selectedTypeCarburant = null;
                                    selectedTypeVehicule = null;
                                  });
                                  fetchVehicules();
                                },
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Réinitialiser',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showVehiculeFormDialog(),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: Text('Ajouter un véhicule', style: GoogleFonts.poppins(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF002244)),
                                ),
                              )
                            : filteredVehicules.isEmpty
                                ? Center(
                                    child: Text(
                                      'Aucun véhicule trouvé',
                                      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                                    ),
                                  )
                                : GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.6,
                                    ),
                                    itemCount: filteredVehicules.length,
                                    itemBuilder: (context, index) => _buildVehiculeCard(filteredVehicules[index]),
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

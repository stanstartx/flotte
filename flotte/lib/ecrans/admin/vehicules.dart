import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flotte/widgets/menu_admin/admin_menu.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VehiculePage extends StatefulWidget {
  const VehiculePage({super.key});

  @override
  State<VehiculePage> createState() => _VehiculePageState();
}

class _VehiculePageState extends State<VehiculePage> {
  String searchQuery = '';
  String selectedStatut = 'Tous';
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
      } else {
        setState(() {
          errorMessage = 'Erreur ${response.statusCode}: ${response.reasonPhrase}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de connexion: $e';
        isLoading = false;
      });
      print("Erreur récupération véhicules: $e");
    }
  }

  Future<void> createVehicule(Map<String, dynamic> vehiculeData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.post(
        Uri.parse('http://192.168.11.243:8000/api/vehicles/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(vehiculeData),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Véhicule créé avec succès')),
        );
        fetchVehicules();
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

  Future<void> updateVehicule(int id, Map<String, dynamic> vehiculeData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.put(
        Uri.parse('http://192.168.11.243:8000/api/vehicles/$id/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(vehiculeData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Véhicule modifié avec succès')),
        );
        fetchVehicules();
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
    }
  }

  List<dynamic> get filteredVehicules {
    return vehicules.where((vehicule) {
      final matchesSearch = 
        vehicule['marque']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
        vehicule['modele']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
        vehicule['immatriculation']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true;
      
      final matchesStatut = selectedStatut == 'Tous' || 
                           (selectedStatut == 'Actif' && vehicule['actif'] == true) ||
                           (selectedStatut == 'Inactif' && vehicule['actif'] == false);
      
      return matchesSearch && matchesStatut;
    }).toList();
  }

  /// ----------- AJOUT / MODIF VEHICULE -------------
  void _showVehiculeFormDialog({Map<String, dynamic>? vehicule}) async {
    final TextEditingController marqueCtrl =
        TextEditingController(text: vehicule?['marque'] ?? '');
    final TextEditingController modeleCtrl =
        TextEditingController(text: vehicule?['modele'] ?? '');
    String typeVoitureValue = vehicule?['type_vehicule'] ?? typesVoiture.first;
    final TextEditingController immatriculationCtrl =
        TextEditingController(text: vehicule?['immatriculation'] ?? '');
    final TextEditingController kilometrageCtrl =
        TextEditingController(text: vehicule?['kilometrage']?.toString() ?? '');
    final TextEditingController capaciteReservoirCtrl =
        TextEditingController(text: vehicule?['capacite_reservoir']?.toString() ?? '');
    final TextEditingController couleurCtrl =
        TextEditingController(text: vehicule?['couleur'] ?? '');
    final TextEditingController prixCtrl =
        TextEditingController(text: vehicule?['prix_acquisition']?.toString() ?? '');
    final TextEditingController chassisCtrl =
        TextEditingController(text: vehicule?['numero_chassis'] ?? '');
    bool statutValue = vehicule?['actif'] ?? true;

    // Dates
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
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 80, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vehicule == null ? 'Ajouter Véhicule' : 'Modifier Véhicule',
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Première ligne
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: marqueCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Marque',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: modeleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Modèle',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Deuxième ligne
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: typeVoitureValue,
                          decoration: const InputDecoration(
                            labelText: 'Type de véhicule',
                            border: OutlineInputBorder(),
                          ),
                          items: typesVoiture.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            typeVoitureValue = value!;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: immatriculationCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Immatriculation',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Troisième ligne
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: kilometrageCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Kilométrage',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: capaciteReservoirCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Capacité réservoir (L)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Quatrième ligne
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: couleurCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Couleur',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: prixCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Prix d\'acquisition (€)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Cinquième ligne
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chassisCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Numéro de chassis',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SwitchListTile(
                          title: const Text('Véhicule actif'),
                          value: statutValue,
                          onChanged: (value) {
                            statutValue = value;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Date d\'acquisition'),
                          subtitle: Text(dateAchat?.toString().split(' ')[0] ?? 'Non définie'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: dateAchat ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              dateAchat = date;
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ListTile(
                          title: const Text('Expiration assurance'),
                          subtitle: Text(dateAssurance?.toString().split(' ')[0] ?? 'Non définie'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: dateAssurance ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (date != null) {
                              dateAssurance = date;
                              setState(() {});
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
                        child: ListTile(
                          title: const Text('Visite technique'),
                          subtitle: Text(dateVisite?.toString().split(' ')[0] ?? 'Non définie'),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: dateVisite ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (date != null) {
                              dateVisite = date;
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ],
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
                          final vehiculeData = {
                            'marque': marqueCtrl.text,
                            'modele': modeleCtrl.text,
                            'type_vehicule': typeVoitureValue,
                            'immatriculation': immatriculationCtrl.text,
                            'kilometrage': double.tryParse(kilometrageCtrl.text) ?? 0.0,
                            'capacite_reservoir': double.tryParse(capaciteReservoirCtrl.text) ?? 0.0,
                            'couleur': couleurCtrl.text,
                            'prix_acquisition': double.tryParse(prixCtrl.text),
                            'numero_chassis': chassisCtrl.text,
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
                        child: Text(vehicule == null ? 'Ajouter' : 'Modifier'),
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
  }

  /// ----------- VOIR VEHICULE -------------
  void _showVehiculeDetailDialog(Map<String, dynamic> vehicule) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 80, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      "Détails Véhicule",
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("Marque : ${vehicule['marque']}"),
                  Text("Modèle : ${vehicule['modele']}"),
                  Text("Type : ${vehicule['type_vehicule']}"),
                  Text("Immatriculation : ${vehicule['immatriculation']}"),
                  Text("Kilométrage : ${vehicule['kilometrage']} km"),
                  Text("Capacité réservoir : ${vehicule['capacite_reservoir']} L"),
                  Text("Couleur : ${vehicule['couleur']}"),
                  Text("Prix d'acquisition : ${vehicule['prix_acquisition'] != null ? '${vehicule['prix_acquisition']}€' : 'Non défini'}"),
                  Text("Numéro de chassis : ${vehicule['numero_chassis'] ?? 'Non défini'}"),
                  if (vehicule['date_acquisition'] != null)
                    Text("Date d'acquisition : ${DateFormat('dd/MM/yyyy').format(DateTime.parse(vehicule['date_acquisition']))}"),
                  if (vehicule['assurance_expiration'] != null)
                    Text("Expiration assurance : ${DateFormat('dd/MM/yyyy').format(DateTime.parse(vehicule['assurance_expiration']))}"),
                  if (vehicule['visite_technique'] != null)
                    Text("Visite technique : ${DateFormat('dd/MM/yyyy').format(DateTime.parse(vehicule['visite_technique']))}"),
                  Text("Statut : ${vehicule['actif'] ? 'Actif' : 'Inactif'}"),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Télécharger fiche PDF
                      },
                      icon: const Icon(Icons.download),
                      label: const Text("Télécharger"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF002244),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ----------- TABLEAU VEHICULES -------------
  Widget _buildVehiculeTable(List<dynamic> vehicules) {
    final filteredVehicules = vehicules.where((v) {
      final matchesSearch =
          v['marque']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
              v['modele']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
              v['immatriculation']!
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase());
      final matchesStatus =
          selectedStatut == 'Tous' || v['actif'] == (selectedStatut == 'Actif');
      return matchesSearch && matchesStatus;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Marque / Modèle')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Immatriculation')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Actions')),
          ],
          rows: filteredVehicules.map((v) {
            return DataRow(
              cells: [
                DataCell(Text('${v['marque']} / ${v['modele']}')),
                DataCell(Text(v['type_vehicule'])),
                DataCell(Text(v['immatriculation']!)),
                DataCell(Text(v['actif'] ? 'Actif' : 'Inactif')),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye,
                            color: Colors.blue),
                        tooltip: "Voir",
                        onPressed: () => _showVehiculeDetailDialog(v),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: "Modifier",
                        onPressed: () => _showVehiculeFormDialog(vehicule: v),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: "Supprimer",
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirmer la suppression'),
                              content: Text('Êtes-vous sûr de vouloir supprimer le véhicule ${v['marque']} ${v['modele']} ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    deleteVehicule(v['id']);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// ----------- UI PRINCIPALE -------------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FC),
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
              if (!isMobile) const AdminMenu(),
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
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF002244)),
                        ),
                      const SizedBox(height: 16),

                      // Gestion des erreurs
                      if (errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
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

                      /// Filtres
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 240,
                                child: TextField(
                                  onChanged: (value) =>
                                      setState(() => searchQuery = value),
                                  decoration: const InputDecoration(
                                    labelText: 'Rechercher un véhicule',
                                    hintText:
                                        'Marque, modèle, immatriculation...',
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: DropdownButtonFormField<String>(
                                  value: selectedStatut,
                                  onChanged: (value) =>
                                      setState(() => selectedStatut = value!),
                                  decoration: const InputDecoration(
                                    labelText: 'Statut',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: statuts
                                      .map((e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ))
                                      .toList(),
                                ),
                              ),
                              IconButton(
                                onPressed: fetchVehicules,
                                icon: const Icon(Icons.refresh),
                                tooltip: 'Actualiser',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      /// Bouton Ajouter Véhicule en haut à droite
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _showVehiculeFormDialog(),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: Text(
                              "Ajouter un véhicule",
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF002244),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      /// Tableau unique
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : vehicules.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Aucun véhicule trouvé',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  )
                                : _buildVehiculeTable(vehicules),
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

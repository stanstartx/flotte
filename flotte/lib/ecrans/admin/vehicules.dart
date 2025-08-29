import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flotte/widgets/menu_admin/admin_menu.dart';

class VehiculePage extends StatefulWidget {
  const VehiculePage({super.key});

  @override
  State<VehiculePage> createState() => _VehiculePageState();
}

class _VehiculePageState extends State<VehiculePage> {
  String searchQuery = '';
  String selectedStatut = 'Tous';

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
    'Essence',
    'Diesel',
    'Électrique',
    'Hybride'
  ];

  final List<Map<String, dynamic>> vehicules = [
    {
      'marque': 'Toyota',
      'modele': 'Corolla',
      'typeVoiture': 'Berline',
      'immatriculation': 'CI-1234-AB',
      'statut': 'Actif',
      'kilometrage': '12000',
      'carburant': 'Essence',
      'dateAchat': '01/01/2022',
      'assurance': '01/01/2024',
      'dateVisiteTechnique': '01/01/2024',
      'capaciteReservoir': '50',
      'couleur': 'Blanc',
    },
  ];

  /// ----------- AJOUT / MODIF VEHICULE -------------
  void _showVehiculeFormDialog({Map<String, dynamic>? vehicule}) async {
    final TextEditingController marqueCtrl =
        TextEditingController(text: vehicule?['marque'] ?? '');
    final TextEditingController modeleCtrl =
        TextEditingController(text: vehicule?['modele'] ?? '');
    String typeVoitureValue = vehicule?['typeVoiture'] ?? typesVoiture.first;
    final TextEditingController immatriculationCtrl =
        TextEditingController(text: vehicule?['immatriculation'] ?? '');
    final TextEditingController kilometrageCtrl =
        TextEditingController(text: vehicule?['kilometrage'] ?? '');
    String carburantValue = vehicule?['carburant'] ?? typesCarburant.first;
    final TextEditingController dateAchatCtrl =
        TextEditingController(text: vehicule?['dateAchat'] ?? '');
    final TextEditingController assuranceCtrl =
        TextEditingController(text: vehicule?['assurance'] ?? '');
    final TextEditingController dateVisiteCtrl =
        TextEditingController(text: vehicule?['dateVisiteTechnique'] ?? '');
    final TextEditingController capaciteReservoirCtrl =
        TextEditingController(text: vehicule?['capaciteReservoir'] ?? '');
    final TextEditingController couleurCtrl =
        TextEditingController(text: vehicule?['couleur'] ?? '');
    bool statutValue = vehicule?['statut'] == 'Actif' || vehicule == null;

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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vehicule == null ? 'Ajouter Véhicule' : 'Modifier Véhicule',
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: marqueCtrl,
                    decoration: const InputDecoration(labelText: 'Marque'),
                  ),
                  TextField(
                    controller: modeleCtrl,
                    decoration: const InputDecoration(labelText: 'Modèle'),
                  ),
                  DropdownButtonFormField<String>(
                    value: typeVoitureValue,
                    onChanged: (val) => setState(() => typeVoitureValue = val!),
                    decoration:
                        const InputDecoration(labelText: 'Type de voiture'),
                    items: typesVoiture
                        .map((type) =>
                            DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                  ),
                  TextField(
                    controller: immatriculationCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Immatriculation'),
                  ),
                  TextField(
                    controller: kilometrageCtrl,
                    decoration: const InputDecoration(labelText: 'Kilométrage'),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<String>(
                    value: carburantValue,
                    onChanged: (val) => setState(() => carburantValue = val!),
                    decoration:
                        const InputDecoration(labelText: 'Type de carburant'),
                    items: typesCarburant
                        .map((type) =>
                            DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                  ),
                  TextField(
                    controller: dateAchatCtrl,
                    readOnly: true,
                    decoration:
                        const InputDecoration(labelText: 'Date d\'achat'),
                    onTap: () async {
                      DateTime? date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        dateAchatCtrl.text =
                            DateFormat('dd/MM/yyyy').format(date);
                      }
                    },
                  ),
                  TextField(
                    controller: assuranceCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: 'Date expiration assurance'),
                    onTap: () async {
                      DateTime? date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        assuranceCtrl.text =
                            DateFormat('dd/MM/yyyy').format(date);
                      }
                    },
                  ),
                  TextField(
                    controller: dateVisiteCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: 'Date visite technique'),
                    onTap: () async {
                      DateTime? date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        dateVisiteCtrl.text =
                            DateFormat('dd/MM/yyyy').format(date);
                      }
                    },
                  ),
                  TextField(
                    controller: capaciteReservoirCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Capacité du réservoir (L)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: couleurCtrl,
                    decoration: const InputDecoration(labelText: 'Couleur'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Statut : '),
                      Switch(
                        value: statutValue,
                        onChanged: (val) => setState(() => statutValue = val),
                      ),
                      Text(statutValue ? 'Actif' : 'Inactif')
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Sauvegarder / Mettre à jour
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF002244),
                        foregroundColor: Colors.white),
                    child: Text(vehicule == null ? 'Ajouter' : 'Mettre à jour'),
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
                  Text("Type : ${vehicule['typeVoiture']}"),
                  Text("Immatriculation : ${vehicule['immatriculation']}"),
                  Text("Kilométrage : ${vehicule['kilometrage']} km"),
                  Text("Carburant : ${vehicule['carburant']}"),
                  Text("Date d'achat : ${vehicule['dateAchat']}"),
                  Text("Assurance : ${vehicule['assurance']}"),
                  Text("Visite technique : ${vehicule['dateVisiteTechnique']}"),
                  Text(
                      "Capacité réservoir : ${vehicule['capaciteReservoir']} L"),
                  Text("Couleur : ${vehicule['couleur']}"),
                  Text("Statut : ${vehicule['statut']}"),
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
  Widget _buildVehiculeTable(List<Map<String, dynamic>> vehicules) {
    final filteredVehicules = vehicules.where((v) {
      final matchesSearch =
          v['marque']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
              v['modele']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
              v['immatriculation']!
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase());
      final matchesStatus =
          selectedStatut == 'Tous' || v['statut'] == selectedStatut;
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
                DataCell(Text(v['typeVoiture'])),
                DataCell(Text(v['immatriculation']!)),
                DataCell(Text(v['statut']!)),
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
                          // TODO: supprimer
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
                      Expanded(child: _buildVehiculeTable(vehicules)),
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

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flotte/widgets/menu_admin/admin_menu.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage>
    with SingleTickerProviderStateMixin {
  String searchQuery = '';
  String selectedType = 'Tous';
  late TabController _tabController;
  String? filePath;

  final List<String> types = [
    'Tous',
    'Carte grise',
    'Assurance',
    'Contrôle technique',
    'Contrat de location',
  ];

  final List<Map<String, String>> vehiculeDocuments = [
    {
      'type': 'Assurance',
      'vehicule': 'Renault Clio - AB123CD',
      'conducteur': 'Jean Dupont',
      'dateEmission': '01/01/2025',
      'dateExpiration': '31/12/2025',
      'file': 'assurance.pdf',
      'etat': 'Valide',
    },
  ];

  final List<Map<String, String>> conducteurDocuments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showAddEditDocumentModal({Map<String, String>? doc}) {
    String type = doc?['type'] ?? 'Carte grise';
    String vehicule = doc?['vehicule'] ?? '';
    String conducteur = doc?['conducteur'] ?? '';
    String dateEmission = doc?['dateEmission'] ?? '';
    String dateExpiration = doc?['dateExpiration'] ?? '';
    String? selectedFile = doc?['file'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc == null ? 'Ajouter un document' : 'Modifier le document',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),
                TextField(
                  controller: TextEditingController(text: type),
                  onChanged: (v) => type = v,
                  decoration: const InputDecoration(
                    labelText: 'Type de document',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: vehicule),
                  onChanged: (v) => vehicule = v,
                  decoration: const InputDecoration(
                    labelText: 'Véhicule',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: conducteur),
                  onChanged: (v) => conducteur = v,
                  decoration: const InputDecoration(
                    labelText: 'Conducteur',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: dateEmission),
                  onChanged: (v) => dateEmission = v,
                  decoration: const InputDecoration(
                    labelText: 'Date d\'émission',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: dateExpiration),
                  onChanged: (v) => dateExpiration = v,
                  decoration: const InputDecoration(
                    labelText: 'Date d\'expiration',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Champ téléversement
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedFile ?? 'Aucun fichier sélectionné',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles();
                        if (result != null) {
                          setState(() {
                            selectedFile = result.files.single.name;
                            filePath = selectedFile;
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Téléverser'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler')),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        final map = {
                          'type': type,
                          'vehicule': vehicule,
                          'conducteur': conducteur,
                          'dateEmission': dateEmission,
                          'dateExpiration': dateExpiration,
                          'file': selectedFile ?? '',
                          'etat': 'Valide',
                        };
                        if (doc == null) {
                          if (_tabController.index == 0) {
                            vehiculeDocuments.add(map);
                          } else {
                            conducteurDocuments.add(map);
                          }
                        } else {
                          doc.addAll(map);
                        }
                        setState(() {});
                        Navigator.pop(context);
                      },
                      child: Text(doc == null ? 'Ajouter' : 'Modifier'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentDetail(Map<String, String> doc) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Détails du document',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 24),
              Text('Type: ${doc['type']}'),
              Text('Véhicule: ${doc['vehicule']}'),
              Text('Conducteur: ${doc['conducteur']}'),
              Text('Date d\'émission: ${doc['dateEmission']}'),
              Text('Date d\'expiration: ${doc['dateExpiration']}'),
              Text('État: ${doc['etat']}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Télécharger PDF'),
                    onPressed: () {
                      // logique téléchargement
                    },
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fermer'))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTable(List<Map<String, String>> docs) {
    final filteredDocs = docs.where((doc) {
      final matchesSearch =
          doc['type']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
              (doc['vehicule'] ?? '')
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              (doc['conducteur'] ?? '')
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase());

      final matchesType = selectedType == 'Tous' || doc['type'] == selectedType;
      return matchesSearch && matchesType;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Véhicule')),
            DataColumn(label: Text('Conducteur')),
            DataColumn(label: Text('Période')),
            DataColumn(label: Text('État')),
            DataColumn(label: Text('Actions')),
          ],
          rows: filteredDocs.map((doc) {
            return DataRow(cells: [
              DataCell(Text(doc['type']!)),
              DataCell(Text(doc['vehicule'] ?? '')),
              DataCell(Text(doc['conducteur'] ?? '')),
              DataCell(
                  Text('${doc['dateEmission']} - ${doc['dateExpiration']}')),
              DataCell(Text(doc['etat'] ?? '')),
              DataCell(Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                    onPressed: () => _showDocumentDetail(doc),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => _showAddEditDocumentModal(doc: doc),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      docs.remove(doc);
                      setState(() {});
                    },
                  )
                ],
              ))
            ]);
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bool isMobile = constraints.maxWidth < 700;

      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
        drawer: isMobile ? const AdminMenu() : null,
        appBar: isMobile
            ? AppBar(
                title: Text(
                  'Documents',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.white, // texte blanc
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                ),
                backgroundColor: const Color(0xFF002244),
                iconTheme: const IconThemeData(
                  color: Colors.white, // menu hamburger blanc
                ),
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
                        'Gestion des Documents',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF002244),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Recherche & filtres
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
                                onChanged: (v) =>
                                    setState(() => searchQuery = v),
                                decoration: const InputDecoration(
                                  labelText: 'Rechercher',
                                  hintText: 'Véhicule, conducteur, type...',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 200,
                              child: DropdownButtonFormField<String>(
                                value: selectedType,
                                onChanged: (v) =>
                                    setState(() => selectedType = v!),
                                decoration: const InputDecoration(
                                  labelText: 'Type de document',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: types
                                    .map((e) => DropdownMenuItem(
                                        value: e, child: Text(e)))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ajouter document
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddEditDocumentModal(),
                        icon: const Icon(Icons.upload_file),
                        label: const Text("Ajouter un document"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF002244),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Onglets documents
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                      tabs: const [
                        Tab(text: 'Documents Véhicules'),
                        Tab(text: 'Documents Conducteurs'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDocumentTable(vehiculeDocuments),
                          _buildDocumentTable(conducteurDocuments),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

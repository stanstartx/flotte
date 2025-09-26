import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';
import 'package:application_conducteur/services/documents_service.dart';
import 'package:file_picker/file_picker.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final Color primaryColor = const Color(0xFF1C6DD0);
  final Color secondaryColor = const Color(0xFF4F9CF9);
  final Color textPrimary = const Color(0xFF1A202C);

  List<Map<String, dynamic>> conducteurDocs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await DocumentsService.fetchDocuments();
      // Mapping minimal pour l'affichage
      final mapped = data.map<Map<String, dynamic>>((d) {
        final map = Map<String, dynamic>.from(d);
        String titre = (map['titre'] ?? map['title'] ?? map['name'] ?? 'Document').toString();
        String etat = (map['etat'] ?? map['status'] ?? '—').toString();
        String expiration = (map['expiration'] ?? map['date_expiration'] ?? map['expires_at'] ?? '').toString();
        return {"titre": titre, "etat": etat, "expiration": expiration, "file": null};
      }).toList();
      setState(() {
        conducteurDocs = mapped;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: isMobile ? const Menu() : null,
      appBar:
          isMobile
              ? AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: IconThemeData(color: primaryColor),
                title: Text(
                  "Documents",
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                  ),
                ),
                centerTitle: false,
              )
              : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 🔥 contenu en haut
        children: [
          if (!isMobile) const Menu(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 32,
                vertical: isMobile ? 20 : 40,
              ),
              child: Align(
                alignment: Alignment.topCenter, // 🔥 centré horizontalement
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile)
                        Row(
                          children: [
                            Icon(
                              Icons.description,
                              size: 32,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Documents",
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      if (!isMobile) const SizedBox(height: 16),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddDocumentDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text("Ajouter un document"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Liste des documents
                      _loading
                          ? const Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _error != null
                              ? Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        "Erreur: $_error",
                                        style: GoogleFonts.poppins(color: Colors.red),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: _fetchDocuments,
                                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                                        child: const Text('Réessayer'),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            conducteurDocs.map((doc) {
                              return GestureDetector(
                                onTap: () => _showDocumentDetails(context, doc),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  width: isMobile ? double.infinity : 700,
                                  child: _DocumentCard(
                                    titre: doc["titre"],
                                    etat: doc["etat"],
                                    expiration: doc["expiration"],
                                    couleurStatut:
                                        doc["etat"] == "Valide"
                                            ? primaryColor
                                            : (doc["etat"] == "Expiré"
                                                ? Colors.redAccent
                                                : Colors.orangeAccent),
                                  ),
                                ),
                              );
                            }).toList(),
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

  void _showDocumentDetails(BuildContext context, Map<String, dynamic> doc) {
    final TextEditingController titreController = TextEditingController(
      text: doc["titre"],
    );
    final TextEditingController expirationController = TextEditingController(
      text: doc["expiration"],
    );
    String etat = doc["etat"];

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Détails du document",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titreController,
                    decoration: const InputDecoration(labelText: "Titre"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: expirationController,
                    decoration: const InputDecoration(
                      labelText: "Date d'expiration",
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: etat,
                    items:
                        ["Valide", "Bientôt expiré", "Expiré"]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) etat = val;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Fermer"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            doc["titre"] = titreController.text;
                            doc["expiration"] = expirationController.text;
                            doc["etat"] = etat;
                          });
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Enregistrer"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showAddDocumentDialog(BuildContext context) {
    final TextEditingController titreController = TextEditingController();
    final TextEditingController expirationController = TextEditingController();
    String etat = "Valide";
    File? selectedFile;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Ajouter un document",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titreController,
                    decoration: const InputDecoration(
                      labelText: "Titre du document",
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: expirationController,
                    decoration: const InputDecoration(
                      labelText: "Date d'expiration",
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: etat,
                    items:
                        ["Valide", "Bientôt expiré", "Expiré"]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) etat = val;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles();
                      if (result != null) {
                        selectedFile = File(result.files.single.path!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "${result.files.single.name} sélectionné",
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Téléverser un fichier"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (titreController.text.isEmpty || selectedFile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sélectionnez un fichier et indiquez un titre.')),
                        );
                        return;
                      }
                      try {
                        await DocumentsService.uploadDocument(
                          file: selectedFile!,
                          title: titreController.text,
                          expiration: expirationController.text.isNotEmpty ? expirationController.text : null,
                          status: etat,
                        );
                        if (!mounted) return;
                        Navigator.of(context).pop();
                        await _fetchDocuments();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Document téléversé.')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur upload: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Ajouter"),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final String titre;
  final String etat;
  final String expiration;
  final Color couleurStatut;

  const _DocumentCard({
    required this.titre,
    required this.etat,
    required this.expiration,
    required this.couleurStatut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file, color: couleurStatut, size: 36),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Expiration : $expiration",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            etat,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: couleurStatut,
            ),
          ),
        ],
      ),
    );
  }
}

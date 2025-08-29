import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';

enum DocumentType { conducteur, vehicule }

class DocumentModel {
  String titre;
  String dateExpiration; // au format jj/mm/aaaa
  String statut; // "Valide", "Bientôt expiré", "Expiré"
  String pdfUrl;
  DocumentType type;

  DocumentModel({
    required this.titre,
    required this.dateExpiration,
    required this.statut,
    required this.pdfUrl,
    required this.type,
  });
}

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final TextEditingController _searchController = TextEditingController();

  // Liste complète des documents (mutable pour le CRUD)
  List<DocumentModel> allDocuments = [
    DocumentModel(
      titre: 'Permis de conduire',
      dateExpiration: '22/12/2026',
      statut: 'Valide',
      pdfUrl: 'https://groupe-laroche.com/docs/permis.pdf',
      type: DocumentType.conducteur,
    ),
    DocumentModel(
      titre: 'Assurance Santé',
      dateExpiration: '30/06/2025',
      statut: 'Valide',
      pdfUrl: 'https://groupe-laroche.com/docs/sante.pdf',
      type: DocumentType.conducteur,
    ),
    DocumentModel(
      titre: 'Carte Grise',
      dateExpiration: '20/11/2025',
      statut: 'Bientôt expiré',
      pdfUrl: 'https://groupe-laroche.com/docs/carte_grise.pdf',
      type: DocumentType.vehicule,
    ),
    DocumentModel(
      titre: 'Assurance Véhicule',
      dateExpiration: '15/04/2024',
      statut: 'Expiré',
      pdfUrl: 'https://groupe-laroche.com/docs/assurance.pdf',
      type: DocumentType.vehicule,
    ),
  ];

  // États du filtre et tri
  DocumentType? _filterType; // null = tous
  String? _filterStatut; // null = tous
  String _searchText = '';
  String _sortField = 'dateExpiration'; // ou 'titre' ou 'statut'
  bool _sortAsc = true;

  Color _statutColor(String statut) {
    switch (statut) {
      case 'Valide':
        return Colors.green.shade700;
      case 'Bientôt expiré':
        return Colors.orange.shade700;
      case 'Expiré':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade800;
    }
  }

  IconData _iconForType(DocumentType type) {
    return type == DocumentType.conducteur
        ? Icons.person
        : Icons.directions_car_filled;
  }

  // Fonction utilitaire pour comparer les dates jj/mm/aaaa
  int _compareDate(String d1, String d2) {
    try {
      final parts1 = d1.split('/');
      final parts2 = d2.split('/');
      final date1 = DateTime(
        int.parse(parts1[2]),
        int.parse(parts1[1]),
        int.parse(parts1[0]),
      );
      final date2 = DateTime(
        int.parse(parts2[2]),
        int.parse(parts2[1]),
        int.parse(parts2[0]),
      );
      return date1.compareTo(date2);
    } catch (e) {
      return 0;
    }
  }

  // Filtrer, chercher, trier
  List<DocumentModel> get filteredDocuments {
    List<DocumentModel> docs =
        allDocuments.where((doc) {
          final matchesType = _filterType == null || doc.type == _filterType;
          final matchesStatut =
              _filterStatut == null || doc.statut == _filterStatut;
          final matchesSearch = doc.titre.toLowerCase().contains(
            _searchText.toLowerCase(),
          );
          return matchesType && matchesStatut && matchesSearch;
        }).toList();

    docs.sort((a, b) {
      int result = 0;
      switch (_sortField) {
        case 'dateExpiration':
          result = _compareDate(a.dateExpiration, b.dateExpiration);
          break;
        case 'titre':
          result = a.titre.toLowerCase().compareTo(b.titre.toLowerCase());
          break;
        case 'statut':
          result = a.statut.toLowerCase().compareTo(b.statut.toLowerCase());
          break;
      }
      return _sortAsc ? result : -result;
    });

    return docs;
  }

  // Ouvre un dialog formulaire pour ajout ou modification
  Future<void> _openForm({DocumentModel? doc, int? index}) async {
    final formKey = GlobalKey<FormState>();

    String titre = doc?.titre ?? '';
    String dateExpiration = doc?.dateExpiration ?? '';
    String statut = doc?.statut ?? 'Valide';
    String pdfUrl = doc?.pdfUrl ?? '';
    DocumentType type = doc?.type ?? DocumentType.conducteur;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              doc == null ? 'Ajouter un document' : 'Modifier le document',
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titre
                    TextFormField(
                      initialValue: titre,
                      decoration: const InputDecoration(labelText: 'Titre'),
                      validator:
                          (val) =>
                              (val == null || val.isEmpty)
                                  ? 'Champ requis'
                                  : null,
                      onSaved: (val) => titre = val!.trim(),
                    ),
                    // Date expiration
                    TextFormField(
                      initialValue: dateExpiration,
                      decoration: const InputDecoration(
                        labelText: 'Date d\'expiration (jj/mm/aaaa)',
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Champ requis';
                        // Vérifier format basique
                        final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                        if (!regex.hasMatch(val)) return 'Format invalide';
                        return null;
                      },
                      onSaved: (val) => dateExpiration = val!.trim(),
                    ),
                    // Statut
                    DropdownButtonFormField<String>(
                      value: statut,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items:
                          ['Valide', 'Bientôt expiré', 'Expiré']
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) statut = val;
                      },
                    ),
                    // URL PDF
                    TextFormField(
                      initialValue: pdfUrl,
                      decoration: const InputDecoration(labelText: 'URL PDF'),
                      validator:
                          (val) =>
                              (val == null || val.isEmpty)
                                  ? 'Champ requis'
                                  : null,
                      onSaved: (val) => pdfUrl = val!.trim(),
                    ),
                    // Type
                    DropdownButtonFormField<DocumentType>(
                      value: type,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items:
                          DocumentType.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t == DocumentType.conducteur
                                        ? 'Conducteur'
                                        : 'Véhicule',
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) type = val;
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    formKey.currentState!.save();

                    final newDoc = DocumentModel(
                      titre: titre,
                      dateExpiration: dateExpiration,
                      statut: statut,
                      pdfUrl: pdfUrl,
                      type: type,
                    );

                    setState(() {
                      if (doc != null && index != null) {
                        allDocuments[index] = newDoc;
                      } else {
                        allDocuments.add(newDoc);
                      }
                    });

                    Navigator.of(context).pop();
                  }
                },
                child: Text(doc == null ? 'Ajouter' : 'Modifier'),
              ),
            ],
          ),
    );
  }

  // Suppression avec confirmation
  Future<void> _deleteDocument(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content: Text(
              'Voulez-vous supprimer le document "${allDocuments[index].titre}" ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() {
        allDocuments.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    // Documents filtrés triés
    final docs = filteredDocuments;

    // Séparer par type pour affichage sectionné
    final conducteurDocs =
        docs.where((d) => d.type == DocumentType.conducteur).toList();
    final vehiculeDocs =
        docs.where((d) => d.type == DocumentType.vehicule).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      drawer: isMobile ? const Menu() : null,
      appBar: AppBar(
        title: const Text('📁 Mes documents'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            tooltip: 'Ajouter un document',
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: Row(
        children: [
          if (!isMobile) const Menu(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recherche
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Rechercher par titre...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon:
                            _searchText.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchText = '';
                                    });
                                  },
                                )
                                : null,
                      ),
                      onChanged:
                          (val) => setState(() => _searchText = val.trim()),
                    ),
                    const SizedBox(height: 16),

                    // Filtres et tri dans une Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Wrap(
                          runSpacing: 12,
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Filtre type
                            DropdownButton<DocumentType?>(
                              value: _filterType,
                              hint: const Text('Filtrer par type'),
                              items: [
                                const DropdownMenuItem<DocumentType?>(
                                  value: null,
                                  child: Text('Tous types'),
                                ),
                                DropdownMenuItem<DocumentType?>(
                                  value: DocumentType.conducteur,
                                  child: const Text('Conducteur'),
                                ),
                                DropdownMenuItem<DocumentType?>(
                                  value: DocumentType.vehicule,
                                  child: const Text('Véhicule'),
                                ),
                              ],
                              onChanged:
                                  (val) => setState(() => _filterType = val),
                            ),

                            // Filtre statut
                            DropdownButton<String?>(
                              value: _filterStatut,
                              hint: const Text('Filtrer par statut'),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Tous statuts'),
                                ),
                                ...['Valide', 'Bientôt expiré', 'Expiré'].map(
                                  (s) => DropdownMenuItem<String?>(
                                    value: s,
                                    child: Text(s),
                                  ),
                                ),
                              ],
                              onChanged:
                                  (val) => setState(() => _filterStatut = val),
                            ),

                            // Tri champ
                            DropdownButton<String>(
                              value: _sortField,
                              items: [
                                DropdownMenuItem(
                                  value: 'dateExpiration',
                                  child: const Text('Trier par date'),
                                ),
                                DropdownMenuItem(
                                  value: 'titre',
                                  child: const Text('Trier par titre'),
                                ),
                                DropdownMenuItem(
                                  value: 'statut',
                                  child: const Text('Trier par statut'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _sortField = val);
                              },
                            ),

                            // Tri ordre
                            IconButton(
                              tooltip:
                                  _sortAsc
                                      ? 'Tri croissant'
                                      : 'Tri décroissant',
                              icon: Icon(
                                _sortAsc
                                    ? Icons.arrow_upward
                                    : Icons.arrow_downward,
                              ),
                              onPressed:
                                  () => setState(() => _sortAsc = !_sortAsc),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sections documents conducteurs et véhicules
                    _buildSection('Documents du conducteur', conducteurDocs),
                    const SizedBox(height: 32),
                    _buildSection('Documents du véhicule', vehiculeDocs),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<DocumentModel> documents) {
    if (documents.isEmpty) {
      return Text(
        'Aucun document disponible.',
        style: GoogleFonts.poppins(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children:
              documents.asMap().entries.map((entry) {
                final doc = entry.value;
                // index dans allDocuments (important pour CRUD)
                final globalIndex = allDocuments.indexOf(doc);
                return _buildDocumentCard(doc, globalIndex);
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildDocumentCard(DocumentModel doc, int index) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _iconForType(doc.type),
            color: _statutColor(doc.statut),
            size: 30,
          ),
          const SizedBox(height: 12),
          Text(
            doc.titre,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Expiration : ${doc.dateExpiration}',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _statutColor(doc.statut).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              doc.statut,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: _statutColor(doc.statut),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: ouvrir PDF dans une visionneuse ou navigateur
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Voir PDF'),
              ),
              const SizedBox(width: 8),
              // Modifier
              IconButton(
                tooltip: 'Modifier',
                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                onPressed: () => _openForm(doc: doc, index: index),
              ),
              // Supprimer
              IconButton(
                tooltip: 'Supprimer',
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deleteDocument(index),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

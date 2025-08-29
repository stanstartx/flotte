import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';
import 'package:url_launcher/url_launcher.dart';

enum DocumentType { conducteur, vehicule }

class DocumentModel {
  final String titre;
  final String dateExpiration;
  final String statut;
  final String pdfUrl;
  final DocumentType type;
  final String? vehiculeNom;

  DocumentModel({
    required this.titre,
    required this.dateExpiration,
    required this.statut,
    required this.pdfUrl,
    required this.type,
    this.vehiculeNom,
  });
}

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  final List<DocumentModel> allDocuments = [
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
      vehiculeNom: 'Toyota RAV4 - AB123CD',
    ),
    DocumentModel(
      titre: 'Assurance',
      dateExpiration: '15/04/2024',
      statut: 'Expiré',
      pdfUrl: 'https://groupe-laroche.com/docs/assurance.pdf',
      type: DocumentType.vehicule,
      vehiculeNom: 'Toyota RAV4 - AB123CD',
    ),
    DocumentModel(
      titre: 'Carte Grise',
      dateExpiration: '01/10/2026',
      statut: 'Valide',
      pdfUrl: 'https://groupe-laroche.com/docs/cg_voiture2.pdf',
      type: DocumentType.vehicule,
      vehiculeNom: 'Peugeot 208 - CD456EF',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Map<String, List<DocumentModel>> _groupDocumentsByVehicule(
    List<DocumentModel> docs,
  ) {
    final Map<String, List<DocumentModel>> map = {};
    for (var doc in docs) {
      final nom = doc.vehiculeNom ?? 'Véhicule inconnu';
      map.putIfAbsent(nom, () => []);
      map[nom]!.add(doc);
    }
    return map;
  }

  void _openAddDocumentDialog() {
    final _formKey = GlobalKey<FormState>();
    String titre = '';
    String dateExpiration = '';
    String statut = 'Valide';
    String pdfUrl = '';
    DocumentType type = DocumentType.conducteur;
    String? vehiculeNom;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            constraints: const BoxConstraints(maxWidth: 480),
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ajouter un document',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Titre',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Champ requis'
                                      : null,
                          onChanged: (value) => titre = value,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Date d\'expiration (jj/mm/aaaa)',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Champ requis'
                                      : null,
                          onChanged: (value) => dateExpiration = value,
                          keyboardType: TextInputType.datetime,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Statut',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                          value: statut,
                          items:
                              ['Valide', 'Bientôt expiré', 'Expiré']
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null)
                              setStateDialog(() => statut = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'URL PDF',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Champ requis'
                                      : null,
                          onChanged: (value) => pdfUrl = value,
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<DocumentType>(
                          decoration: const InputDecoration(
                            labelText: 'Type de document',
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                          ),
                          value: type,
                          items:
                              DocumentType.values
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(
                                        e == DocumentType.conducteur
                                            ? 'Conducteur'
                                            : 'Véhicule',
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null)
                              setStateDialog(() => type = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        if (type == DocumentType.vehicule)
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Nom du véhicule',
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (type == DocumentType.vehicule &&
                                  (value == null || value.isEmpty)) {
                                return 'Champ requis pour véhicule';
                              }
                              return null;
                            },
                            onChanged: (value) => vehiculeNom = value,
                          ),
                        if (type == DocumentType.vehicule)
                          const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                textStyle: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Annuler'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                textStyle: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: () {
                                if (_formKey.currentState?.validate() ??
                                    false) {
                                  setState(() {
                                    allDocuments.add(
                                      DocumentModel(
                                        titre: titre,
                                        dateExpiration: dateExpiration,
                                        statut: statut,
                                        pdfUrl: pdfUrl,
                                        type: type,
                                        vehiculeNom: vehiculeNom,
                                      ),
                                    );
                                  });
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text('Ajouter'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final conducteurDocs =
        allDocuments.where((d) => d.type == DocumentType.conducteur).toList();
    final vehiculeDocs =
        allDocuments.where((d) => d.type == DocumentType.vehicule).toList();
    final groupedVehicules = _groupDocumentsByVehicule(vehiculeDocs);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD),
      drawer: isMobile ? const Menu() : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!isMobile) const Menu(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: isMobile ? 16 : 32,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header avec bouton "Ajouter un document"
                      isMobile
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Builder(
                                    builder: (context) {
                                      return IconButton(
                                        icon: const Icon(
                                          Icons.menu_rounded,
                                          color: Colors.teal,
                                          size: 30,
                                        ),
                                        onPressed: () {
                                          Scaffold.of(context).openDrawer();
                                        },
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.folder_open_rounded,
                                    size: 30,
                                    color: Colors.teal,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Mes documents',
                                      style: GoogleFonts.poppins(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0B1D34),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _openAddDocumentDialog,
                                  icon: Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: Colors.teal.shade50,
                                    size: 24,
                                  ),
                                  label: Text(
                                    'Ajouter un document',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade700,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    elevation: 5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36),
                            ],
                          )
                          : Row(
                            children: [
                              const Icon(
                                Icons.folder_open_rounded,
                                size: 36,
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Mes documents',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0B1D34),
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: _openAddDocumentDialog,
                                borderRadius: BorderRadius.circular(28),
                                hoverColor: Colors.teal.withOpacity(0.12),
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade700.withOpacity(
                                      0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: Colors.teal.shade700.withOpacity(
                                        0.35,
                                      ),
                                      width: 1.3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.teal.shade300.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 18,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline_rounded,
                                        color: Colors.teal.shade800,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Ajouter un document',
                                        style: GoogleFonts.poppins(
                                          color: Colors.teal.shade900,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                      const SizedBox(height: 20),
                      // Section Conducteur
                      Text(
                        'Documents du conducteur',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.blueGrey.shade900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 22,
                        runSpacing: 22,
                        direction: isMobile ? Axis.vertical : Axis.horizontal,
                        children:
                            conducteurDocs.map((doc) {
                              return SizedBox(
                                width: isMobile ? double.infinity : 280,
                                child: FadeTransition(
                                  opacity: CurvedAnimation(
                                    parent: _animationController,
                                    curve: Curves.easeOut,
                                  ),
                                  child: _PremiumDocumentCard(document: doc),
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 50),
                      // Section Véhicules
                      Text(
                        'Documents des véhicules assignés',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.blueGrey.shade900,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ...groupedVehicules.entries.map((entry) {
                        final vehiculeNom = entry.key;
                        final docs = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 34),
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2F855A).withOpacity(0.08),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehiculeNom,
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 18 : 19,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.teal.shade900,
                                ),
                              ),
                              const SizedBox(height: 26),
                              Wrap(
                                spacing: 24,
                                runSpacing: 24,
                                direction:
                                    isMobile ? Axis.vertical : Axis.horizontal,
                                children:
                                    docs.map((doc) {
                                      return SizedBox(
                                        width: isMobile ? double.infinity : 280,
                                        child: FadeTransition(
                                          opacity: CurvedAnimation(
                                            parent: _animationController,
                                            curve: Curves.easeOut,
                                          ),
                                          child: _PremiumDocumentCard(
                                            document: doc,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumDocumentCard extends StatefulWidget {
  final DocumentModel document;

  const _PremiumDocumentCard({required this.document});

  @override
  State<_PremiumDocumentCard> createState() => _PremiumDocumentCardState();
}

class _PremiumDocumentCardState extends State<_PremiumDocumentCard> {
  bool _isHovered = false;

  Color _statutColor(String statut) {
    switch (statut) {
      case 'Valide':
        return Colors.green.shade700;
      case 'Bientôt expiré':
        return Colors.orange.shade700;
      case 'Expiré':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _statusIcon(String statut) {
    switch (statut) {
      case 'Valide':
        return Icons.verified_rounded;
      case 'Bientôt expiré':
        return Icons.schedule_rounded;
      case 'Expiré':
        return Icons.error_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Future<void> _openPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir le document PDF")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final color = _statutColor(doc.statut);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: 280,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient:
              _isHovered
                  ? LinearGradient(
                    colors: [
                      Colors.teal.shade50,
                      Colors.teal.shade100.withOpacity(0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : null,
          color: _isHovered ? null : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow:
              _isHovered
                  ? [
                    BoxShadow(
                      color: Colors.teal.shade200.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 3,
                      offset: const Offset(0, 8),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: const Color(0xFF2F855A).withOpacity(0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          border: Border.all(
            color: _isHovered ? Colors.teal.shade300 : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doc.titre,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.teal.shade900,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: Colors.blueGrey.shade400,
                ),
                const SizedBox(width: 6),
                Text(
                  'Expiration : ${doc.dateExpiration}',
                  style: GoogleFonts.poppins(
                    color: Colors.blueGrey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(_statusIcon(doc.statut), color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  doc.statut,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton.icon(
                onPressed: () => _openPdf(doc.pdfUrl),
                icon: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.teal,
                ),
                label: Text(
                  'Voir PDF',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.teal.shade700,
                    fontSize: 15,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.teal.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

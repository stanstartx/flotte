import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';
import 'package:intl/intl.dart';

class AlertesPage extends StatefulWidget {
  const AlertesPage({super.key});

  @override
  State<AlertesPage> createState() => _AlertesPageState();
}

class _AlertesPageState extends State<AlertesPage> {
  final Color primaryColor = const Color(0xFF1C6DD0);
  final Color secondaryColor = const Color(0xFF4F9CF9);
  final Color textPrimary = const Color(0xFF1A202C);

  int selectedTab = 0; // 0=Toutes, 1=Critique, 2=Warning

  List<Map<String, dynamic>> alertes = [
    {
      'type': 'Permis',
      'niveau': 'warning',
      'message': 'Permis expirant dans 10 jours',
      'vehicule': 'AB-123-CD',
      'conducteur': 'John Doe',
      'date': DateTime(2025, 8, 28),
    },
    {
      'type': 'Assurance',
      'niveau': 'critique',
      'message': 'Assurance expirée',
      'vehicule': 'XY-456-ZW',
      'conducteur': 'Jane Smith',
      'date': DateTime(2025, 8, 20),
    },
    {
      'type': 'Entretien',
      'niveau': 'warning',
      'message': 'Vidange à effectuer',
      'vehicule': 'CD-789-EF',
      'conducteur': 'Alice Konan',
      'date': DateTime(2025, 8, 25),
    },
    {
      'type': 'Contrôle_technique',
      'niveau': 'critique',
      'message': 'CT expiré',
      'vehicule': 'GH-321-IJ',
      'conducteur': 'Bob Martin',
      'date': DateTime(2025, 8, 18),
    },
    {
      'type': 'Permis',
      'niveau': '',
      'message': 'Permis vérifié récemment',
      'vehicule': 'KL-654-MN',
      'conducteur': 'John Doe',
      'date': DateTime(2025, 8, 22),
    },
  ];

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    // Filtrer par onglet
    List<Map<String, dynamic>> filtered =
        selectedTab == 0
            ? alertes
            : alertes
                .where(
                  (a) =>
                      a['niveau'].toLowerCase() ==
                      (selectedTab == 1 ? 'critique' : 'warning'),
                )
                .toList();

    // Trier par date décroissante
    filtered.sort((a, b) => (b['date'] as DateTime).compareTo(a['date']));

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
                  "Alertes",
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                  ),
                ),
              )
              : null,
      body: Row(
        children: [
          if (!isMobile) const Menu(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 32,
                vertical: isMobile ? 20 : 40,
              ),
              child: Align(
                alignment: Alignment.topCenter, // <-- forcé en haut
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile)
                        Row(
                          children: [
                            Icon(
                              Icons.notifications,
                              size: 32,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Alertes",
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      if (!isMobile) const SizedBox(height: 24),

                      // Onglets
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildTabButton("Toutes", 0, isMobile),
                          _buildTabButton("Critiques", 1, isMobile),
                          _buildTabButton("Warnings", 2, isMobile),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Liste des alertes
                      filtered.isEmpty
                          ? Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Center(
                              child: Text(
                                "Aucune alerte",
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                          : Column(
                            children:
                                filtered
                                    .map(
                                      (a) => _AlerteCard(
                                        type: a['type'],
                                        niveau: a['niveau'],
                                        message: a['message'],
                                        vehicule: a['vehicule'],
                                        conducteur: a['conducteur'],
                                        date: DateFormat(
                                          'dd MMM yyyy',
                                        ).format(a['date']),
                                      ),
                                    )
                                    .toList(),
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

  Widget _buildTabButton(String label, int index, bool isMobile) {
    return SizedBox(
      width: isMobile ? (MediaQuery.of(context).size.width / 3) - 20 : null,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedTab = index;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              selectedTab == index ? primaryColor : Colors.grey.shade200,
          foregroundColor: selectedTab == index ? Colors.white : textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _AlerteCard extends StatelessWidget {
  final String type;
  final String niveau;
  final String message;
  final String vehicule;
  final String conducteur;
  final String date;

  const _AlerteCard({
    required this.type,
    required this.niveau,
    required this.message,
    required this.vehicule,
    required this.conducteur,
    required this.date,
  });

  Color _getColorForNiveau() {
    switch (niveau.toLowerCase()) {
      case 'critique':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return const Color(0xFF1C6DD0);
    }
  }

  IconData _getIconForType() {
    switch (type.toLowerCase()) {
      case 'permis':
        return Icons.badge_outlined;
      case 'assurance':
        return Icons.verified_user_outlined;
      case 'controle_technique':
        return Icons.build_circle_outlined;
      case 'entretien':
        return Icons.build;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final couleur = _getColorForNiveau();
    bool isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(maxWidth: 700),
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
          Icon(_getIconForType(), color: couleur, size: 36),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Véhicule: $vehicule - Conducteur: $conducteur',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showDetails(context, couleur),
            style: ElevatedButton.styleFrom(
              backgroundColor: couleur.withOpacity(0.1),
              foregroundColor: couleur,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text("Voir détails"),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, Color couleur) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 20,
            child: Container(
              constraints: BoxConstraints(
                maxWidth:
                    isMobile ? MediaQuery.of(context).size.width * 0.9 : 500,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Détails",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: couleur,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _detailRow(
                      Icons.notification_important,
                      "Type:",
                      type,
                      couleur,
                    ),
                    _detailRow(Icons.warning, "Niveau:", niveau, couleur),
                    _detailRow(
                      Icons.directions_car,
                      "Véhicule:",
                      vehicule,
                      couleur,
                    ),
                    _detailRow(
                      Icons.person,
                      "Conducteur:",
                      conducteur,
                      couleur,
                    ),
                    _detailRow(Icons.message, "Message:", message, couleur),
                    _detailRow(Icons.date_range, "Date:", date, couleur),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "Fermer",
                          style: GoogleFonts.poppins(
                            color: couleur,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color couleur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: couleur, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: const Color(0xFF4A5568),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

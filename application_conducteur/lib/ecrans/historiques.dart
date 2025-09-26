import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';
import 'package:application_conducteur/services/mission_service.dart';
import 'package:application_conducteur/services/trips_service.dart';
import 'package:intl/intl.dart';

class HistoriquesPage extends StatefulWidget {
  const HistoriquesPage({super.key});

  @override
  State<HistoriquesPage> createState() => _HistoriquesPageState();
}

class _HistoriquesPageState extends State<HistoriquesPage> {
  // Couleurs alignées avec connexion.dart
  final Color primaryColor = const Color(
    0xFF1C6DD0,
  ); // bleu principal connexion
  final Color secondaryColor = const Color(0xFF4F9CF9); // bleu clair connexion
  final Color textPrimary = const Color(0xFF1A202C);

  DateTime? selectedDate;
  int selectedTab = 0; // 0 = Missions, 1 = Trajets

  List<Map<String, dynamic>> historiquesMissions = [];
  List<Map<String, dynamic>> historiquesTrajets = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        MissionService.fetchMissions(forceRefresh: true),
        TripsService.fetchDriverTrips(),
      ]);

      final missionsRaw = results[0] as List<Map<String, dynamic>>;
      final tripsRaw = results[1] as List<Map<String, dynamic>>;

      final missions = missionsRaw
          .where((m) => ((m['statut'] ?? '').toString().toLowerCase() == 'terminée' || (m['statut'] ?? '').toString().toLowerCase() == 'annulée'))
          .map<Map<String, dynamic>>((m) {
        final dateStr = (m['date'] ?? '').toString();
        DateTime? date;
        if (dateStr.isNotEmpty) {
          date = DateTime.tryParse(dateStr);
        }
        return {
          'date': date ?? DateTime.now(),
          'nom': m['titre'] ?? 'Mission',
          'lieu': '${m['depart'] ?? ''} → ${m['arrivee'] ?? ''}',
          'statut': m['statut'] ?? '',
          'duree': '',
          'conducteur': '',
          'vehicule': '',
          'commentaires': m['description'] ?? '',
        };
      }).toList();

      final trips = tripsRaw.map<Map<String, dynamic>>((t) {
        DateTime date = DateTime.now();
        final d = t['date'];
        if (d is String) {
          date = DateTime.tryParse(d) ?? date;
        }
        return {
          'date': date,
          'lieu': '${t['depart'] ?? ''} → ${t['arrivee'] ?? ''}',
          'statut': t['statut'] ?? '',
          'duree': t['duree'] ?? '',
          'conducteur': '',
          'vehicule': '',
          'commentaires': '',
        };
      }).toList();

      setState(() {
        historiquesMissions = missions;
        historiquesTrajets = trips;
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

    List<Map<String, dynamic>> dataToShow =
        selectedTab == 0 ? historiquesMissions : historiquesTrajets;

    // Trier par date décroissante
    dataToShow.sort((a, b) => b['date'].compareTo(a['date']));

    List<Map<String, dynamic>> filtered =
        selectedDate == null
            ? dataToShow
            : dataToShow.where((h) {
              return h['date'].day == selectedDate!.day &&
                  h['date'].month == selectedDate!.month &&
                  h['date'].year == selectedDate!.year;
            }).toList();

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
                  "Historique",
                  style: GoogleFonts.poppins(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                  ),
                ),
                centerTitle: false,
              )
              : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Erreur: $_error', style: GoogleFonts.poppins(color: Colors.red)),
                      const SizedBox(height: 8),
                      ElevatedButton(onPressed: _fetchHistory, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : Row(
        children: [
          if (!isMobile) const Menu(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 32,
                vertical: isMobile ? 20 : 40,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(Icons.history, size: 32, color: primaryColor),
                            const SizedBox(width: 12),
                            Text(
                              "Historique",
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      if (!isMobile) const SizedBox(height: 16),

                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildTabButton("Missions", 0, isMobile),
                          _buildTabButton("Trajets", 1, isMobile),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickDate,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: primaryColor,
                              backgroundColor: secondaryColor.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.date_range_outlined),
                            label: Text(
                              selectedDate != null
                                  ? DateFormat(
                                    'dd MMM yyyy',
                                  ).format(selectedDate!)
                                  : 'Filtrer par date',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Export PDF global
                            },
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text("Exporter PDF"),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                            ),
                          ),
                          if (selectedDate != null)
                            TextButton(
                              onPressed: () {
                                setState(() => selectedDate = null);
                              },
                              child: const Text("Réinitialiser"),
                            ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      Column(
                        children:
                            filtered
                                .map(
                                  (h) => Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    width: isMobile ? double.infinity : 700,
                                    child: _MissionCard(
                                      date: DateFormat(
                                        'dd MMM yyyy',
                                      ).format(h['date']),
                                      lieu:
                                          selectedTab == 0
                                              ? h['nom']
                                              : h['lieu'],
                                      statut: h['statut'],
                                      couleurStatut:
                                          selectedTab == 0
                                              ? (h['statut'] == 'Terminée'
                                                  ? primaryColor
                                                  : Colors.redAccent)
                                              : (h['statut'] == 'Effectué'
                                                  ? primaryColor
                                                  : Colors.orangeAccent),
                                      duree: h['duree'],
                                      conducteur: h['conducteur'],
                                      vehicule: h['vehicule'],
                                      commentaires: h['commentaires'],
                                    ),
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
      width: isMobile ? (MediaQuery.of(context).size.width / 2) - 32 : null,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedTab = index;
            selectedDate = null;
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Sélectionnez une date',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: primaryColor),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }
}

class _MissionCard extends StatelessWidget {
  final String date;
  final String lieu;
  final String statut;
  final Color couleurStatut;
  final String duree;
  final String conducteur;
  final String vehicule;
  final String commentaires;

  const _MissionCard({
    required this.date,
    required this.lieu,
    required this.statut,
    required this.couleurStatut,
    required this.duree,
    required this.conducteur,
    required this.vehicule,
    required this.commentaires,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
          Icon(Icons.directions_car, color: couleurStatut, size: 36),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lieu,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showDetails(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: couleurStatut.withOpacity(0.1),
              foregroundColor: couleurStatut,
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

  void _showDetails(BuildContext context) {
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
                        color: couleurStatut,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _detailRow(Icons.calendar_today_outlined, "Date :", date),
                    _detailRow(Icons.place_outlined, "Trajet :", lieu),
                    _detailRow(
                      Icons.directions_car_filled_outlined,
                      "Véhicule :",
                      vehicule,
                    ),
                    _detailRow(Icons.access_time_outlined, "Durée :", duree),
                    _detailRow(
                      Icons.person_outline,
                      "Conducteur :",
                      conducteur,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Commentaires",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: couleurStatut.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        commentaires,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF4A5568),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO : Logique d'impression
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: couleurStatut.withOpacity(0.1),
                            foregroundColor: couleurStatut,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.print),
                          label: const Text("Imprimer"),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO : Logique d'export PDF
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: couleurStatut.withOpacity(0.1),
                            foregroundColor: couleurStatut,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text("Exporter"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "Fermer",
                          style: GoogleFonts.poppins(
                            color: couleurStatut,
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: couleurStatut, size: 20),
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

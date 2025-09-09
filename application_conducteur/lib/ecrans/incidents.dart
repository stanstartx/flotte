import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';
import 'package:intl/intl.dart';

class IncidentsPage extends StatefulWidget {
  const IncidentsPage({super.key});

  @override
  State<IncidentsPage> createState() => _IncidentsPageState();
}

class _IncidentsPageState extends State<IncidentsPage> {
  final Color primaryColor = const Color(0xFF1C6DD0);
  final Color secondaryColor = const Color(0xFF4F9CF9);
  final Color textPrimary = const Color(0xFF1A202C);

  DateTime? selectedDate;
  String selectedVehicule = 'Tous';
  final List<String> vehicules = [
    'Tous',
    'Toyota Hilux',
    'Nissan Navara',
    'Ford Ranger',
  ];

  final List<Map<String, String>> incidents = [
    {
      'vehicule': 'Toyota Hilux',
      'type': 'Panne moteur',
      'date': '01/09/2025',
      'heure': '08:45',
      'statut': 'Non résolu',
      'commentaires': 'Le moteur ne démarre pas.',
    },
    {
      'vehicule': 'Toyota Hilux',
      'type': 'Crevaison',
      'date': '01/09/2025',
      'heure': '12:00',
      'statut': 'Résolu',
      'commentaires': 'Changement de pneu effectué.',
    },
    {
      'vehicule': 'Nissan Navara',
      'type': 'Accident léger',
      'date': '30/08/2025',
      'heure': '14:30',
      'statut': 'Résolu',
      'commentaires': 'Rayure sur portière.',
    },
    {
      'vehicule': 'Ford Ranger',
      'type': 'Retard livraison',
      'date': '29/08/2025',
      'heure': '10:15',
      'statut': 'Non résolu',
      'commentaires': 'Traffic dense.',
    },
    {
      'vehicule': 'Ford ',
      'type': 'Defaut de materielle',
      'date': '28/08/2025',
      'heure': '10:15',
      'statut': 'Non résolu',
      'commentaires': 'Traffic dense.',
    },
    {
      'vehicule': 'Mercedes',
      'type': 'Retard livraison',
      'date': '19/08/2025',
      'heure': '10:15',
      'statut': 'Non résolu',
      'commentaires': 'Traffic dense.',
    },
  ];

  List<Map<String, String>> get filteredIncidents {
    final today = DateTime(2025, 9, 1);
    return incidents.where((i) {
      final vehiculeMatch =
          selectedVehicule == 'Tous' || i['vehicule'] == selectedVehicule;
      if (selectedDate != null) {
        final parts = i['date']!.split('/');
        final incidentDate = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
        return vehiculeMatch && incidentDate == selectedDate;
      }
      return vehiculeMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

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
                  "Incidents",
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
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile)
                        Row(
                          children: [
                            Icon(
                              Icons.report_problem,
                              size: 32,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Incidents",
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          DropdownButton<String>(
                            value: selectedVehicule,
                            items:
                                vehicules
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v,
                                        child: Text(v),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              setState(() {
                                selectedVehicule = v!;
                              });
                            },
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickDate,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: primaryColor,
                              backgroundColor: secondaryColor.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
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
                          if (selectedDate != null)
                            TextButton(
                              onPressed:
                                  () => setState(() => selectedDate = null),
                              child: const Text("Réinitialiser"),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      Column(
                        children:
                            filteredIncidents.map((incident) {
                              final statutColor =
                                  incident['statut'] == 'Résolu'
                                      ? Colors.green
                                      : Colors.redAccent;
                              return _IncidentCard(
                                vehicule: incident['vehicule']!,
                                type: incident['type']!,
                                date: incident['date']!,
                                heure: incident['heure']!,
                                statut: incident['statut']!,
                                commentaires: incident['commentaires']!,
                                couleurStatut: statutColor,
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }
}

class _IncidentCard extends StatelessWidget {
  final String vehicule;
  final String type;
  final String date;
  final String heure;
  final String statut;
  final String commentaires;
  final Color couleurStatut;

  const _IncidentCard({
    required this.vehicule,
    required this.type,
    required this.date,
    required this.heure,
    required this.statut,
    required this.commentaires,
    required this.couleurStatut,
  });

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 700;

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
          Icon(Icons.report_problem, color: couleurStatut, size: 36),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$vehicule - $type',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$date à $heure',
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
                    _detailRow(
                      Icons.calendar_today_outlined,
                      "Date :",
                      "$date à $heure",
                    ),
                    _detailRow(
                      Icons.directions_car_filled_outlined,
                      "Véhicule :",
                      vehicule,
                    ),
                    _detailRow(Icons.report_problem, "Type :", type),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Commentaires",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
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
                          onPressed: () {},
                          icon: const Icon(Icons.print),
                          label: const Text("Imprimer"),
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
                        ),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text("Exporter"),
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

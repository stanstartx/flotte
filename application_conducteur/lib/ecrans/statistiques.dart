import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';
import 'package:fl_chart/fl_chart.dart';

const Color kGreenDark = Color(0xFF14532D);
const Color kGreen = Color(0xFF22C55E);
const Color kBlue = Color(0xFF2563EB);
const Color kOrange = Color(0xFFF59E42);
const Color kRed = Color(0xFFEF4444);
const Color kGreyText = Color(0xFF64748B);
const Color kBlack = Color(0xFF1E293B);
const Color kWhite = Colors.white;

class StatistiquesPage extends StatelessWidget {
  const StatistiquesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    // Exemple de données
    final statsMissions = [
      {'label': 'À faire', 'count': 2, 'color': kBlue},
      {'label': 'Acceptées', 'count': 1, 'color': kGreen},
      {'label': 'Refusées', 'count': 0, 'color': kRed},
      {'label': 'Terminées', 'count': 5, 'color': kGreyText},
    ];

    final double totalKilometrage = 142000;
    final double carburantMoyen = 62; // en %
    final List<String> notifications = [
      "🚨 Mission urgente à Abobo à 10h30",
      "⚠️ Carburant faible sur Toyota Hilux",
      "🛠 Véhicule Nissan Navara prochain entretien",
    ];

    return Scaffold(
      backgroundColor: kWhite,
      appBar:
          isMobile
              ? AppBar(
                backgroundColor: kWhite,
                elevation: 0,
                iconTheme: const IconThemeData(color: kBlue),
                title: Text(
                  'Statistiques',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: kBlack,
                  ),
                ),
              )
              : null,
      drawer: isMobile ? const Menu() : null,
      body: Row(
        children: [
          if (!isMobile) const Menu(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile)
                        Row(
                          children: [
                            Icon(Icons.bar_chart, size: 32, color: kBlue),
                            const SizedBox(width: 12),
                            Text(
                              'Mes statistiques',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 28,
                                color: kBlack,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 30),

                      // Statistiques missions
                      Text(
                        'Missions par statut',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: kBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              statsMissions
                                  .map(
                                    (s) => _StatCard(
                                      label: s['label'] as String,
                                      count: s['count'] as int,
                                      color: s['color'] as Color,
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Graphique missions
                      Text(
                        'Répartition missions',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: kGreenDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 250,
                        child: _PieChartMissions(statsMissions: statsMissions),
                      ),
                      const SizedBox(height: 30),

                      // Kilométrage et carburant
                      Row(
                        children: [
                          _InfoCard(
                            title: 'Kilométrage total',
                            value: '${totalKilometrage.toInt()} km',
                            color: kOrange,
                            icon: Icons.speed,
                          ),
                          const SizedBox(width: 16),
                          _InfoCard(
                            title: 'Carburant moyen',
                            value: '${carburantMoyen.toInt()} %',
                            color: kBlue,
                            icon: Icons.local_gas_station,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Notifications importantes
                      Text(
                        'Notifications importantes',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: kRed,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children:
                            notifications
                                .map(
                                  (notif) => Card(
                                    elevation: 2,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.notification_important,
                                        color: kRed,
                                      ),
                                      title: Text(
                                        notif,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 30),

                      // Performance conducteur
                      Text(
                        'Indicateurs de performance',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: kGreenDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _InfoCard(
                            title: 'Missions réussies',
                            value:
                                '${statsMissions[3]['count']} sur ${statsMissions.map((s) => s['count'] as int).reduce((a, b) => a + b)}',
                            color: kGreen,
                            icon: Icons.check_circle,
                          ),
                          const SizedBox(width: 16),
                          _InfoCard(
                            title: 'Missions refusées',
                            value: '${statsMissions[2]['count']}',
                            color: kRed,
                            icon: Icons.cancel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _InfoCard(
                            title: 'Moyenne km/mission',
                            value:
                                '${(totalKilometrage / (statsMissions.map((s) => s['count'] as int).reduce((a, b) => a + b))).toStringAsFixed(0)} km',
                            color: kOrange,
                            icon: Icons.timeline,
                          ),
                          const SizedBox(width: 16),
                          _InfoCard(
                            title: 'Carburant moyen',
                            value: '${carburantMoyen.toInt()} %',
                            color: kBlue,
                            icon: Icons.local_gas_station,
                          ),
                        ],
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
}

// Carte de stat
class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(right: 18),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.poppins(fontSize: 14, color: color)),
        ],
      ),
    );
  }
}

// Carte info
class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  const _InfoCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kBlack,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Pie chart missions
class _PieChartMissions extends StatelessWidget {
  final List<Map> statsMissions;
  const _PieChartMissions({required this.statsMissions});

  @override
  Widget build(BuildContext context) {
    final sections =
        statsMissions
            .where((s) => (s['count'] as int) > 0)
            .map(
              (s) => PieChartSectionData(
                value: (s['count'] as int).toDouble(),
                color: s['color'] as Color,
                title: '${s['count']}',
                radius: 60,
                titleStyle: GoogleFonts.poppins(
                  color: kWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
            .toList();

    return PieChart(
      PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 4),
    );
  }
}

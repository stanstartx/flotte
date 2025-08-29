import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flotte/widgets/menu_admin/admin_menu.dart';

class StatistiquesPage extends StatelessWidget {
  const StatistiquesPage({super.key});

  // === STAT CARD ===
  Widget buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    Color color = Colors.blue,
    double? trendValue,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (trendValue != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    trendValue >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: trendValue >= 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${trendValue >= 0 ? '+' : ''}${trendValue.toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: trendValue >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  // === LINE CHART ===
  Widget buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                return Text(
                  months[value.toInt() % months.length],
                  style: GoogleFonts.poppins(fontSize: 12),
                );
              },
              interval: 1,
              reservedSize: 24,
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            color: Colors.blue,
            dotData: FlDotData(show: false),
            spots: const [
              FlSpot(0, 10),
              FlSpot(1, 12),
              FlSpot(2, 8),
              FlSpot(3, 15),
              FlSpot(4, 13),
              FlSpot(5, 17),
            ],
          ),
        ],
      ),
    );
  }

  // === PIE CHART ===
  Widget buildPieChart() {
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 32,
        sections: [
          PieChartSectionData(
            value: 40,
            title: 'Livraison',
            color: Colors.green,
            radius: 50,
          ),
          PieChartSectionData(
            value: 30,
            title: 'Maintenance',
            color: Colors.orange,
            radius: 50,
          ),
          PieChartSectionData(
            value: 20,
            title: 'Inspection',
            color: Colors.blue,
            radius: 50,
          ),
          PieChartSectionData(
            value: 10,
            title: 'Autres',
            color: Colors.grey,
            radius: 50,
          ),
        ],
      ),
    );
  }

  // === BAR CHART ===
  Widget buildBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 30,
        barGroups: [
          BarChartGroupData(
              x: 0,
              barRods: [BarChartRodData(toY: 24, color: Colors.green)],
              showingTooltipIndicators: [0]),
          BarChartGroupData(
              x: 1,
              barRods: [BarChartRodData(toY: 3, color: Colors.redAccent)],
              showingTooltipIndicators: [0]),
          BarChartGroupData(
              x: 2,
              barRods: [BarChartRodData(toY: 6, color: Colors.orange)],
              showingTooltipIndicators: [0]),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
              sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final labels = ['Actifs', 'Panne', 'Maintenance'];
              return Text(
                labels[value.toInt()],
                style: GoogleFonts.poppins(fontSize: 12),
              );
            },
          )),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
        ),
      ),
    );
  }

  // === TIMELINE ===
  Widget buildTimeline() {
    final items = [
      {
        'icon': Icons.warning,
        'text': "Véhicule AB-123-CD en maintenance",
        'color': Colors.orange
      },
      {
        'icon': Icons.check_circle,
        'text': "Mission 'Livraison A123' complétée",
        'color': Colors.green
      },
      {
        'icon': Icons.upload_file,
        'text': "Document 'Assurance.pdf' expiré",
        'color': Colors.red
      },
      {
        'icon': Icons.person_add,
        'text': "Nouveau conducteur assigné",
        'color': Colors.blue
      },
      {
        'icon': Icons.local_gas_station,
        'text': "Carburant ajouté : 500L",
        'color': Colors.teal
      },
    ];

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading:
              Icon(item['icon'] as IconData, color: item['color'] as Color),
          title: Text(item['text'] as String, style: GoogleFonts.poppins()),
          tileColor: (item['color'] as Color).withOpacity(0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      },
    );
  }

  // === CARD GRAPHIQUE ===
  Widget buildChartCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      height: 250,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          drawer: isMobile ? const AdminMenu() : null,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: const Color(0xFF002244),
                  iconTheme: const IconThemeData(color: Colors.white),
                  title: Text(
                    "STATISTIQUES",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!isMobile) const AdminMenu(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile)
                        Text(
                          'STATISTIQUES',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF002244),
                          ),
                        ),
                      if (!isMobile) const SizedBox(height: 24),

                      // === STAT CARDS ===
                      isMobile
                          ? SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  buildStatCard(
                                      icon: Icons.directions_car,
                                      title: 'Véhicules actifs',
                                      value: '24',
                                      color: Colors.green,
                                      trendValue: 5),
                                  buildStatCard(
                                      icon: Icons.build_circle,
                                      title: 'Véhicules en panne',
                                      value: '3',
                                      color: Colors.redAccent,
                                      trendValue: -2),
                                  buildStatCard(
                                      icon: Icons.local_shipping,
                                      title: 'Missions en cours',
                                      value: '6',
                                      color: Colors.orange,
                                      trendValue: 10),
                                  buildStatCard(
                                      icon: Icons.speed,
                                      title: 'Km parcourus',
                                      value: '2450 km',
                                      color: Colors.blueAccent,
                                      trendValue: 7),
                                ],
                              ),
                            )
                          : GridView.count(
                              crossAxisCount: 4,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                buildStatCard(
                                    icon: Icons.directions_car,
                                    title: 'Véhicules actifs',
                                    value: '24',
                                    color: Colors.green,
                                    trendValue: 5),
                                buildStatCard(
                                    icon: Icons.build_circle,
                                    title: 'Véhicules en panne',
                                    value: '3',
                                    color: Colors.redAccent,
                                    trendValue: -2),
                                buildStatCard(
                                    icon: Icons.local_shipping,
                                    title: 'Missions en cours',
                                    value: '6',
                                    color: Colors.orange,
                                    trendValue: 10),
                                buildStatCard(
                                    icon: Icons.speed,
                                    title: 'Km parcourus',
                                    value: '2450 km',
                                    color: Colors.blueAccent,
                                    trendValue: 7),
                              ],
                            ),
                      const SizedBox(height: 32),

                      // === GRAPHIQUES ===
                      isMobile
                          ? Column(
                              children: [
                                buildChartCard(buildLineChart()),
                                const SizedBox(height: 16),
                                buildChartCard(buildPieChart()),
                                const SizedBox(height: 16),
                                buildChartCard(buildBarChart()),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      buildChartCard(buildLineChart()),
                                      const SizedBox(height: 16),
                                      buildChartCard(buildBarChart()),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 1,
                                  child: buildChartCard(buildPieChart()),
                                ),
                              ],
                            ),
                      const SizedBox(height: 32),

                      // === TIMELINE ===
                      Container(
                        height: 300,
                        child: buildTimeline(),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';

class TrajetsPage extends StatefulWidget {
  const TrajetsPage({super.key});

  @override
  State<TrajetsPage> createState() => _TrajetsPageState();
}

class _TrajetsPageState extends State<TrajetsPage>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> trajets = [
    {
      'date': '18 Juin 2025',
      'heure': '08:00 - 10:15',
      'depart': 'Abidjan Plateau',
      'arrivee': 'Yopougon Zone Industrielle',
      'distance': '12 km',
      'statut': 'Réalisé',
    },
    {
      'date': '17 Juin 2025',
      'heure': '14:00 - 15:00',
      'depart': 'Treichville',
      'arrivee': 'Marcory Résidentiel',
      'distance': '7 km',
      'statut': 'En attente',
    },
    {
      'date': '02 Mai 2025',
      'heure': '09:00 - 10:00',
      'depart': 'Abidjan Plateau',
      'arrivee': 'Koumassi',
      'distance': '9 km',
      'statut': 'Annulé',
    },
  ];

  late TabController _tabController;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Réalisé':
        return const Color(0xFF2ECC71);
      case 'En attente':
        return const Color(0xFFF39C12);
      case 'Annulé':
        return const Color(0xFFE74C3C);
      default:
        return Colors.grey;
    }
  }

  String extractMonthYear(String date) {
    final parts = date.split(' ');
    if (parts.length >= 3) {
      return '${parts[1]} ${parts[2]}';
    }
    return date;
  }

  Map<String, List<Map<String, dynamic>>> groupByMonth(
    List<Map<String, dynamic>> trajetsList,
  ) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var t in trajetsList) {
      String monthYear = extractMonthYear(t['date']);
      if (!grouped.containsKey(monthYear)) {
        grouped[monthYear] = [];
      }
      grouped[monthYear]!.add(t);
    }
    return grouped;
  }

  Map<String, List<Map<String, dynamic>>> groupByStatus(
    List<Map<String, dynamic>> trajetsList,
  ) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var t in trajetsList) {
      String status = t['statut'];
      if (!grouped.containsKey(status)) {
        grouped[status] = [];
      }
      grouped[status]!.add(t);
    }
    return grouped;
  }

  void showDetailsModal(BuildContext context, Map<String, dynamic> trajet) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Fermer",
      barrierColor: const Color(0xFF2F855A).withOpacity(0.08),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2F855A).withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            width: 420,
            child: Material(
              color: Colors.transparent,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Détails du trajet",
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.green.shade900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.shade700.withOpacity(0.15),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 26,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Infos détaillées
                    _premiumDetailRow(
                      Icons.calendar_today_rounded,
                      "Date",
                      trajet['date'],
                    ),
                    _premiumDetailRow(
                      Icons.access_time_filled,
                      "Heure",
                      trajet['heure'],
                    ),
                    _premiumDetailRow(
                      Icons.location_pin,
                      "Départ",
                      trajet['depart'],
                    ),
                    _premiumDetailRow(Icons.flag, "Arrivée", trajet['arrivee']),
                    _premiumDetailRow(
                      Icons.speed,
                      "Distance",
                      trajet['distance'],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.info_rounded,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(
                              trajet['statut'],
                            ).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            trajet['statut'],
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: getStatusColor(trajet['statut']),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Image Google Maps stylée
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        'https://maps.googleapis.com/maps/api/staticmap?center=Abidjan&zoom=12&size=600x300&markers=color:blue|${Uri.encodeComponent(trajet['depart'])}&markers=color:red|${Uri.encodeComponent(trajet['arrivee'])}&key=VOTRE_CLE_API',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Bouton Fermer premium
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 26,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 6,
                          backgroundColor: Colors.green.shade700,
                          shadowColor: Colors.green.shade900.withOpacity(0.3),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "Fermer",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                            letterSpacing: 1.1,
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
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.scale(
          scale: animation.value,
          child: Opacity(opacity: animation.value, child: child),
        );
      },
    );
  }

  Widget _premiumDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green.shade600, size: 28),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget trajetCard(Map<String, dynamic> trajet) {
    return GestureDetector(
      onTap: () => showDetailsModal(context, trajet),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trajet['date'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(trajet['statut']).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    trajet['statut'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: getStatusColor(trajet['statut']),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.access_time_outlined,
                  color: Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  trajet['heure'],
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "${trajet['depart']} ➜ ${trajet['arrivee']}",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.directions_car_filled_rounded,
                  color: Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  "Distance : ${trajet['distance']}",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    // Filtrage par recherche
    final filteredTrajets =
        trajets.where((trajet) {
          return trajet['depart'].toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              trajet['arrivee'].toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
        }).toList();

    // Groupements pour onglets
    final groupedByMonth = groupByMonth(filteredTrajets);
    final groupedByStatus = groupByStatus(filteredTrajets);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      drawer: isMobile ? const Drawer(child: Menu()) : null,
      appBar:
          isMobile
              ? AppBar(
                backgroundColor: Colors.white,
                iconTheme: IconThemeData(color: Colors.green.shade700),
                elevation: 0,
                title: Text(
                  "Mes trajets",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2F855A),
                  ),
                ),
              )
              : null,
      body: Row(
        children: [
          if (!isMobile) const Menu(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMobile) ...[
                    // Titre + icône
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Mes trajets",
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2F855A),
                          ),
                        ),
                        Icon(
                          Icons.route,
                          color: Colors.green.shade600,
                          size: 30,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Sous-titre + badge semaine
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Historique de la semaine",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Semaine en cours",
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Recherche
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Rechercher un trajet...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Statistiques
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard(
                        "Total",
                        trajets.length.toString(),
                        Icons.list_alt,
                      ),
                      _buildStatCard(
                        "Réalisés",
                        trajets
                            .where((t) => t['statut'] == 'Réalisé')
                            .length
                            .toString(),
                        Icons.check_circle,
                      ),
                      _buildStatCard(
                        "Distance",
                        "${trajets.fold(0, (sum, t) => sum + int.parse(t['distance'].split(' ')[0]))} km",
                        Icons.pin_drop,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Onglets mois / statut / tout
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.green.shade700,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Colors.green.shade700,
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(text: "Par mois"),
                      Tab(text: "Par statut"),
                      Tab(text: "Tous"),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Contenu des onglets
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Par mois
                        ListView.separated(
                          itemCount: groupedByMonth.keys.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 18),
                          itemBuilder: (context, index) {
                            String month = groupedByMonth.keys.elementAt(index);
                            List<Map<String, dynamic>> moisTrajets =
                                groupedByMonth[month]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  month,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...moisTrajets.map(trajetCard).toList(),
                              ],
                            );
                          },
                        ),

                        // Par statut
                        ListView.separated(
                          itemCount: groupedByStatus.keys.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 18),
                          itemBuilder: (context, index) {
                            String statut = groupedByStatus.keys.elementAt(
                              index,
                            );
                            List<Map<String, dynamic>> statutTrajets =
                                groupedByStatus[statut]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statut,
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: getStatusColor(statut),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...statutTrajets.map(trajetCard).toList(),
                              ],
                            );
                          },
                        ),

                        // Tous
                        ListView.separated(
                          itemCount: filteredTrajets.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return trajetCard(filteredTrajets[index]);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text("Voir tous les trajets"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

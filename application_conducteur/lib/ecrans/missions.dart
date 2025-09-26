import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';
import 'package:application_conducteur/services/mission_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class MissionsPage extends StatefulWidget {
  const MissionsPage({super.key});

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> missions = [];
  List<Map<String, dynamic>> notifications = [];
  late TabController _tabController;
  String searchQuery = "";
  bool isLoading = false;

  static const primaryColor = Color(0xFF1E88E5);
  static const secondaryColor = Color(0xFF1C6DD0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // Ajout de l'onglet "En cours"
    _fetchMissions();
    Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) {
        _fetchMissions();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMissions() async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await MissionService.fetchMissions(forceRefresh: true);
      setState(() {
        missions = data;
        isLoading = false;
      });
      debugPrint('Missions fetched: ${data.length} missions');
      for (var mission in data) {
        debugPrint('Mission ID: ${mission['id']}, Statut: ${mission['statut']}, Réponse conducteur: ${mission['reponse_conducteur']}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error in _fetchMissions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des missions: $e')),
      );
    }
  }

  Future<void> _accepterMission(int id) async {
    setState(() {
      isLoading = true;
    });
    try {
      await MissionService.accepterMission(id);
      await Future.delayed(Duration(milliseconds: 500)); // Ajout du délai
      await _fetchMissions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mission acceptée avec succès')),
      );
    } catch (e) {
      debugPrint('Erreur acceptation mission ID $id: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'acceptation de la mission $id: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refuserMission(int id) async {
    setState(() {
      isLoading = true;
    });
    try {
      await MissionService.refuserMission(id);
      await Future.delayed(Duration(milliseconds: 500)); // Ajout du délai
      await _fetchMissions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mission refusée avec succès')),
      );
    } catch (e) {
      debugPrint('Error refusing mission ID $id: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du refus de la mission $id: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'À faire':
        return const Color(0xFFF39C12);
      case 'Acceptée':
        return primaryColor;
      case 'En cours':
        return const Color(0xFF3498DB); // Couleur pour "En cours"
      case 'Refusée':
        return const Color(0xFFE74C3C);
      case 'Terminée':
        return const Color(0xFF2ECC71);
      default:
        return Colors.grey;
    }
  }

  Widget missionCard(Map<String, dynamic> mission, {bool isMobile = false}) {
    final bool peutAccepterOuRefuser = mission['statut'] == 'À faire' && mission['reponse_conducteur'] == 'en_attente';
    return GestureDetector(
      onTap: () => _showMissionDetails(mission),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    mission['titre'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor(mission['statut']).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    mission['statut'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: getStatusColor(mission['statut']),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  color: Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${mission['date']} - ${mission['heure']}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const Divider(
              height: 20,
              color: Colors.grey,
            ),
            Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${mission['depart']} ➜ ${mission['arrivee']}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (peutAccepterOuRefuser)
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : () => _accepterMission(mission['id']),
                    icon: const Icon(Icons.check),
                    label: const Text('Accepter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : () => _refuserMission(mission['id']),
                    icon: const Icon(Icons.close),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE74C3C),
                      side: const BorderSide(color: Color(0xFFE74C3C)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isMobile = false,
  }) {
    Color bgColor;
    Color textColor;

    switch (label) {
      case 'Total':
        bgColor = Colors.grey[100]!;
        textColor = Colors.black87;
        break;
      case 'À faire':
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        break;
      case 'Acceptées':
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[700]!;
        break;
      case 'En cours':
        bgColor = Colors.blue[50]!;
        textColor = Colors.blue[600]!;
        break;
      case 'Terminées':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        break;
      default:
        bgColor = Colors.grey[100]!;
        textColor = Colors.black87;
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsList(
    List<Map<String, dynamic>> missionsList, {
    bool isMobile = false,
  }) {
    if (missionsList.isEmpty) {
      return Center(
        child: Text(
          isLoading ? "Chargement..." : "Aucune mission ici.",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[500]),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.only(bottom: isMobile ? 24 : 12),
      itemCount: missionsList.length,
      separatorBuilder: (_, __) => SizedBox(height: isMobile ? 12 : 16),
      itemBuilder: (context, index) {
        return missionCard(missionsList[index], isMobile: isMobile);
      },
    );
  }

  Widget _buildNotificationsTab({bool isMobile = false}) {
    if (notifications.isEmpty) {
      return Center(
        child: Text(
          "Aucune notification pour le moment.",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[500]),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: isMobile ? 24 : 12),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => SizedBox(height: isMobile ? 12 : 16),
      itemBuilder: (context, index) {
        final notif = notifications[index];
        final bool isMission = notif['titre']?.toLowerCase().contains('mission') ?? false;

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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
                children: [
                  CircleAvatar(
                    backgroundColor: primaryColor,
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif['titre'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif['description'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notif['date'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isMission && notif['reponse_conducteur'] == 'en_attente') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : () => _accepterMission(notif['id']),
                      icon: const Icon(Icons.check),
                      label: const Text("Accepter"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : () => _refuserMission(notif['id']),
                      icon: const Icon(Icons.close),
                      label: const Text("Refuser"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE74C3C),
                        side: const BorderSide(color: Color(0xFFE74C3C)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void showMissionDetailsModal(BuildContext context, Map<String, dynamic> mission) {
    _showMissionDetails(mission);
  }

  void _showMissionDetails(Map<String, dynamic> mission) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Fermer",
      barrierColor: Colors.black.withOpacity(0.2),
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
                  color: Colors.black.withOpacity(0.08),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Détails de la mission",
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
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
                              color: primaryColor.withOpacity(0.15),
                            ),
                            child: Icon(
                              Icons.close,
                              size: 26,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _detailRow(
                      Icons.assignment,
                      "Titre",
                      mission['titre'] ?? '',
                    ),
                    _detailRow(
                      Icons.calendar_today_rounded,
                      "Date",
                      mission['date'] ?? '',
                    ),
                    _detailRow(
                      Icons.access_time_filled,
                      "Heure",
                      mission['heure'] ?? '',
                    ),
                    _detailRow(
                      Icons.location_pin,
                      "Départ",
                      mission['depart'] ?? '',
                    ),
                    _detailRow(Icons.flag, "Arrivée", mission['arrivee'] ?? ''),
                    _detailRow(
                      Icons.description,
                      "Description",
                      mission['description'] ?? '',
                    ),
                    Row(
                      children: [
                        Icon(Icons.info_rounded, color: primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(mission['statut']).withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            mission['statut'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: getStatusColor(mission['statut'] ?? ''),
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
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
                          backgroundColor: primaryColor,
                          shadowColor: primaryColor.withOpacity(0.3),
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 28),
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    final filteredMissions = missions.where((mission) {
      return (mission['titre'] ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
          (mission['depart'] ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
          (mission['arrivee'] ?? '').toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: isMobile ? const Drawer(child: Menu()) : null,
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: secondaryColor),
              title: Text(
                "Mes missions",
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              centerTitle: false,
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) const Menu(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 32,
                vertical: isMobile ? 12 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMobile)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.assignment,
                          color: Colors.blue,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Mes missions",
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A202C),
                          ),
                        ),
                      ],
                    ),
                  if (!isMobile) const SizedBox(height: 10),
                  FutureBuilder<Map<String, int>>(
                    future: MissionService.getMissionStats(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final stats = snapshot.data ?? {
                        'total': 0,
                        'a_faire': 0,
                        'acceptees': 0,
                        'en_cours': 0,
                        'terminees': 0,
                      };
                      return isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildStatCard(
                                  "Total",
                                  stats['total'].toString(),
                                  Icons.list_alt,
                                  Colors.black87,
                                  isMobile: true,
                                ),
                                const SizedBox(height: 12),
                                _buildStatCard(
                                  "À faire",
                                  stats['a_faire'].toString(),
                                  Icons.pending_actions,
                                  Colors.orange[700]!,
                                  isMobile: true,
                                ),
                                const SizedBox(height: 12),
                                _buildStatCard(
                                  "Acceptées",
                                  stats['acceptees'].toString(),
                                  Icons.check_circle_outline,
                                  Colors.blue[700]!,
                                  isMobile: true,
                                ),
                                const SizedBox(height: 12),
                                _buildStatCard(
                                  "En cours",
                                  stats['en_cours'].toString(),
                                  Icons.directions_car,
                                  Colors.blue[600]!,
                                  isMobile: true,
                                ),
                                const SizedBox(height: 12),
                                _buildStatCard(
                                  "Terminées",
                                  stats['terminees'].toString(),
                                  Icons.check_circle,
                                  Colors.green[700]!,
                                  isMobile: true,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    "Total",
                                    stats['total'].toString(),
                                    Icons.list_alt,
                                    Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    "À faire",
                                    stats['a_faire'].toString(),
                                    Icons.pending_actions,
                                    Colors.orange[700]!,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    "Acceptées",
                                    stats['acceptees'].toString(),
                                    Icons.check_circle_outline,
                                    Colors.blue[700]!,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    "En cours",
                                    stats['en_cours'].toString(),
                                    Icons.directions_car,
                                    Colors.blue[600]!,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard(
                                    "Terminées",
                                    stats['terminees'].toString(),
                                    Icons.check_circle,
                                    Colors.green[700]!,
                                  ),
                                ),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Rechercher une mission...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.black87,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: primaryColor,
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                    ),
                    tabs: const [
                      Tab(text: "Toutes"),
                      Tab(text: "À faire"),
                      Tab(text: "Acceptées"),
                      Tab(text: "En cours"),
                      Tab(text: "Terminées"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildMissionsList(
                                filteredMissions,
                                isMobile: isMobile,
                              ),
                              _buildMissionsList(
                                filteredMissions.where((m) => m['statut'] == 'À faire').toList(),
                                isMobile: isMobile,
                              ),
                              _buildMissionsList(
                                filteredMissions.where((m) => m['statut'] == 'Acceptée').toList(),
                                isMobile: isMobile,
                              ),
                              _buildMissionsList(
                                filteredMissions.where((m) => m['statut'] == 'En cours').toList(),
                                isMobile: isMobile,
                              ),
                              _buildMissionsList(
                                filteredMissions.where((m) => m['statut'] == 'Terminée').toList(),
                                isMobile: isMobile,
                              ),
                            ],
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
}
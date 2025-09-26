import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:application_conducteur/config.dart';
import 'package:application_conducteur/services/trips_service.dart';

class TrajetsPage extends StatefulWidget {
  const TrajetsPage({super.key});

  @override
  State<TrajetsPage> createState() => _TrajetsPageState();
}

class _TrajetsPageState extends State<TrajetsPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> trajets = [];
  bool _loading = true;
  String? _error;

  late TabController _tabController;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await TripsService.fetchDriverTrips();
      final mapped = data.map<Map<String, dynamic>>((t) {
        final map = Map<String, dynamic>.from(t);
        final depart = (map['depart'] ?? map['start_location'] ?? map['origin'] ?? '').toString();
        final arrivee = (map['arrivee'] ?? map['end_location'] ?? map['destination'] ?? '').toString();
        final distanceKm = (map['distance_km'] ?? map['distance'] ?? '').toString();
        final status = (map['statut'] ?? map['status'] ?? '').toString();
        String heure = '';
        if (map['heure'] != null) {
          heure = map['heure'].toString();
        } else if (map['start_time'] != null && map['end_time'] != null) {
          heure = '${map['start_time']} - ${map['end_time']}';
        }
        String dateStr = '';
        final dateRaw = map['date'] ?? map['started_at'];
        if (dateRaw is String) {
          dateStr = dateRaw;
        }
        return {
          'date': dateStr,
          'heure': heure,
          'depart': depart,
          'arrivee': arrivee,
          'distance': distanceKm.toString().endsWith('km') ? distanceKm : '${distanceKm} km',
          'statut': status,
        };
      }).toList();
      setState(() {
        trajets = mapped;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Réalisé':
        return const Color(0xFF2ECC71); // vert
      case 'En attente':
        return const Color(0xFFF39C12); // orange
      case 'Annulé':
        return const Color(0xFFE74C3C); // rouge
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

  Widget _buildInteractiveMap(Map<String, dynamic> trajet) {
    // Coordonnées par défaut pour Abidjan
    const LatLng abidjanCenter = LatLng(AppConfig.defaultLatitude, AppConfig.defaultLongitude);
    
    // Coordonnées fictives pour les trajets (à remplacer par de vraies coordonnées)
    final LatLng depart = LatLng(
      abidjanCenter.latitude + (trajet['depart'].hashCode % 100) * 0.001,
      abidjanCenter.longitude + (trajet['depart'].hashCode % 100) * 0.001,
    );
    final LatLng arrivee = LatLng(
      abidjanCenter.latitude + (trajet['arrivee'].hashCode % 100) * 0.001,
      abidjanCenter.longitude + (trajet['arrivee'].hashCode % 100) * 0.001,
    );

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: depart,
            zoom: AppConfig.defaultZoom,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('depart'),
              position: depart,
              infoWindow: InfoWindow(
                title: 'Départ',
                snippet: trajet['depart'],
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            ),
            Marker(
              markerId: const MarkerId('arrivee'),
              position: arrivee,
              infoWindow: InfoWindow(
                title: 'Arrivée',
                snippet: trajet['arrivee'],
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
          },
          polylines: {
            Polyline(
              polylineId: const PolylineId('trajet'),
              points: [depart, arrivee],
              color: Colors.blue,
              width: 3,
            ),
          },
          mapType: MapType.normal,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  void showDetailsModal(BuildContext context, Map<String, dynamic> trajet) {
    const primaryColor = Color(0xFF1E88E5);

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
                          "Détails du trajet",
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
                      Icons.calendar_today_rounded,
                      "Date",
                      trajet['date'],
                    ),
                    _detailRow(
                      Icons.access_time_filled,
                      "Heure",
                      trajet['heure'],
                    ),
                    _detailRow(Icons.location_pin, "Départ", trajet['depart']),
                    _detailRow(Icons.flag, "Arrivée", trajet['arrivee']),
                    _detailRow(Icons.speed, "Distance", trajet['distance']),
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
                    _buildInteractiveMap(trajet),
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
    const primaryColor = Color(0xFF1E88E5);
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

  Widget trajetCard(Map<String, dynamic> trajet) {
    const primaryColor = Color(0xFF1E88E5);
    return GestureDetector(
      onTap: () => showDetailsModal(context, trajet),
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
                    color: Colors.black87,
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
                Icon(Icons.access_time_outlined, color: Colors.grey, size: 18),
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
            const Divider(height: 20, color: Colors.grey),
            Row(
              children: [
                Icon(Icons.location_on_rounded, color: primaryColor, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "${trajet['depart']} ➜ ${trajet['arrivee']}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
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

  Widget statsCard(String title, String value, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
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
              title,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    final filteredTrajets =
        trajets.where((trajet) {
          return trajet['depart'].toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              trajet['arrivee'].toLowerCase().contains(
                searchQuery.toLowerCase(),
              );
        }).toList();

    final groupedByMonth = groupByMonth(filteredTrajets);
    final groupedByStatus = groupByStatus(filteredTrajets);

    int totalTrajets = trajets.length;
    int totalRealises = trajets.where((t) => t['statut'] == 'Réalisé' || t['statut'] == 'Effectué' || t['statut'] == 'Terminé').length;
    int totalDistance = trajets.fold<int>(0, (prev, t) {
      String km = t['distance'].replaceAll(' km', '');
      return prev + int.tryParse(km)!;
    });

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: isMobile ? const Drawer(child: Menu()) : null,
      appBar:
          isMobile
              ? AppBar(
                backgroundColor: Colors.white,
                iconTheme: const IconThemeData(color: Color(0xFF1C6DD0)),
                elevation: 0,
                title: Text(
                  "Mes trajets",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
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
                      ElevatedButton(onPressed: _fetchTrips, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : Row(
        children: [
          if (!isMobile) const Menu(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMobile) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.route, color: Colors.blue, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          "Mes trajets",
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A202C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  Row(
                    children: [
                      statsCard(
                        "Total",
                        "$totalTrajets",
                        Colors.grey[100]!,
                        Colors.black87,
                      ),
                      const SizedBox(width: 16),
                      statsCard(
                        "Réalisés",
                        "$totalRealises",
                        Colors.green[100]!,
                        Colors.green[700]!,
                      ),
                      const SizedBox(width: 16),
                      statsCard(
                        "Distance",
                        "$totalDistance km",
                        Colors.orange[100]!,
                        Colors.orange[700]!,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

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
                      fillColor: Colors.grey[100],
                    ),
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 16),

                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.black87,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: Colors.black87,
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

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
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
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...moisTrajets.map(trajetCard).toList(),
                              ],
                            );
                          },
                        ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

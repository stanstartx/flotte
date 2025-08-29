import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

class TrajetsAdminPage extends StatefulWidget {
  const TrajetsAdminPage({Key? key}) : super(key: key);

  @override
  State<TrajetsAdminPage> createState() => _TrajetsAdminPageState();
}

class _TrajetsAdminPageState extends State<TrajetsAdminPage> {
  List<Map<String, dynamic>> trajets = [];
  bool isLoading = true;
  String? error;

  // Filtres dynamiques
  String? selectedConducteur;
  String? selectedVehicule;
  String? selectedStatut;
  DateTimeRange? selectedRange;
  List<String> conducteurs = [];
  List<String> vehicules = [];
  List<String> statuts = [
    'en_attente',
    'acceptee',
    'refusee',
    'active',
    'terminee'
  ];

  // Pour le drawer de détail
  Map<String, dynamic>? selectedTrajet;

  @override
  void initState() {
    super.initState();
    fetchTrajets();
  }

  Future<void> fetchTrajets() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() {
          error = 'Token non trouvé';
          isLoading = false;
        });
        return;
      }
      final uri = Uri.parse('http://localhost:8000/api/conducteur/missions/');
      final response =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        trajets = data.cast<Map<String, dynamic>>();
        // Récupérer les conducteurs et véhicules uniques pour les filtres
        conducteurs = trajets
            .map((t) => t['driver_details']?['user']?['username'] ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
            .cast<String>();
        vehicules = trajets
            .map((t) => t['vehicle_details']?['plaque'] ?? '')
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
            .cast<String>();
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Erreur API: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Erreur réseau';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredTrajets {
    return trajets.where((t) {
      final conducteur = t['driver_details']?['user']?['username'] ?? '';
      final vehicule = t['vehicle_details']?['plaque'] ?? '';
      final statut = t['statut'] ?? '';
      final date = DateTime.tryParse(t['date_depart'] ?? '') ?? DateTime.now();
      if (selectedConducteur != null && conducteur != selectedConducteur)
        return false;
      if (selectedVehicule != null && vehicule != selectedVehicule)
        return false;
      if (selectedStatut != null && statut != selectedStatut) return false;
      if (selectedRange != null &&
          (date.isBefore(selectedRange!.start) ||
              date.isAfter(selectedRange!.end))) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des trajets'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: fetchTrajets,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistiques',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Exporter',
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildDropdownFilter(
                  label: 'Conducteur',
                  value: selectedConducteur,
                  items: conducteurs,
                  onChanged: (v) => setState(() => selectedConducteur = v),
                ),
                _buildDropdownFilter(
                  label: 'Véhicule',
                  value: selectedVehicule,
                  items: vehicules,
                  onChanged: (v) => setState(() => selectedVehicule = v),
                ),
                _buildDropdownFilter(
                  label: 'Statut',
                  value: selectedStatut,
                  items: statuts,
                  onChanged: (v) => setState(() => selectedStatut = v),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(selectedRange == null
                      ? 'Période'
                      : '${DateFormat('dd/MM/yyyy').format(selectedRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedRange!.end)}'),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2023, 1, 1),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => selectedRange = picked);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF7F9FB),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : isMobile
                  ? Column(
                      children: [
                        _TrajetsStatsCards(trajets: filteredTrajets),
                        Expanded(
                          child: _TrajetsDataTable(
                            trajets: filteredTrajets,
                            onSelect: (t) => setState(() => selectedTrajet = t),
                          ),
                        ),
                        SizedBox(
                          height: 250,
                          child: _TrajetMapWidget(trajet: selectedTrajet),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _TrajetsStatsCards(trajets: filteredTrajets),
                              Expanded(
                                child: _TrajetsDataTable(
                                  trajets: filteredTrajets,
                                  onSelect: (t) =>
                                      setState(() => selectedTrajet = t),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: _TrajetMapWidget(trajet: selectedTrajet),
                        ),
                      ],
                    ),
      endDrawer: selectedTrajet != null
          ? Drawer(
              child: _TrajetDetailDrawer(trajet: selectedTrajet!),
            )
          : null,
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButton<String>(
      value: value,
      hint: Text(label),
      items: items
          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      underline: Container(),
      style: const TextStyle(fontSize: 15),
      borderRadius: BorderRadius.circular(12),
    );
  }
}

// --- Cards Statistiques ---
class _TrajetsStatsCards extends StatelessWidget {
  final List<Map<String, dynamic>> trajets;
  const _TrajetsStatsCards({required this.trajets});

  @override
  Widget build(BuildContext context) {
    final total = trajets.length;
    final distance = trajets.fold<double>(
        0, (s, t) => s + (t['distance_km'] is num ? t['distance_km'] : 0.0));
    final duree = trajets.fold<int>(0, (s, t) {
      final debut = DateTime.tryParse(t['date_depart'] ?? '') ?? DateTime.now();
      final fin = DateTime.tryParse(t['date_arrivee'] ?? '') ?? debut;
      return s + fin.difference(debut).inMinutes;
    });
    final topConducteur = trajets.isNotEmpty
        ? (((trajets
                  ..sort((a, b) =>
                      (b['distance_km'] ?? 0).compareTo(a['distance_km'] ?? 0)))
                .first['driver_details']?['user']?['username']) ??
            '')
        : '';
    final topVehicule = trajets.isNotEmpty
        ? (((trajets
                  ..sort((a, b) =>
                      (b['distance_km'] ?? 0).compareTo(a['distance_km'] ?? 0)))
                .first['vehicle_details']?['plaque']) ??
            '')
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatCard(
            icon: Icons.route,
            label: 'Total trajets',
            value: '$total',
            color: Colors.blue.shade700,
          ),
          _StatCard(
            icon: Icons.straighten,
            label: 'Distance totale',
            value: '${distance.toStringAsFixed(1)} km',
            color: Colors.green.shade700,
          ),
          _StatCard(
            icon: Icons.timer,
            label: 'Durée totale',
            value: '${duree ~/ 60}h${(duree % 60).toString().padLeft(2, '0')}',
            color: Colors.orange.shade700,
          ),
          _StatCard(
            icon: Icons.emoji_events,
            label: 'Top conducteur',
            value: topConducteur,
            color: Colors.purple.shade700,
          ),
          _StatCard(
            icon: Icons.directions_car,
            label: 'Top véhicule',
            value: topVehicule,
            color: Colors.teal.shade700,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: color.withOpacity(0.08),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}

// --- Tableau des trajets ---
class _TrajetsDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> trajets;
  final ValueChanged<Map<String, dynamic>> onSelect;
  const _TrajetsDataTable({required this.trajets, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Conducteur')),
            DataColumn(label: Text('Véhicule')),
            DataColumn(label: Text('Départ')),
            DataColumn(label: Text('Arrivée')),
            DataColumn(label: Text('Distance')),
            DataColumn(label: Text('Raison')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Détail')),
          ],
          rows: trajets.map((t) {
            final user = t['driver_details']?['user_profile']?['user'];
            String conducteurNom = '';
            if (user != null) {
              conducteurNom = [
                user['first_name'] ?? '',
                user['last_name'] ?? ''
              ].where((e) => e.isNotEmpty).join(' ').trim();
              if (conducteurNom.isEmpty) {
                conducteurNom = user['username'] ?? '';
              }
            } else {
              conducteurNom = t['driver_details']?['user']?['username'] ?? '';
            }
            final veh = t['vehicle_details'] ?? {};
            final vehicule = [
              veh['marque'],
              veh['modele'],
              veh['immatriculation']
            ].where((e) => e != null && e.toString().isNotEmpty).join(' - ');
            final depart = t['lieu_depart'] ?? '';
            final arrivee = t['lieu_arrivee'] ?? '';
            final distance = t['distance_km']?.toStringAsFixed(1) ?? '';
            final raison = t['raison'] ?? '';
            final statut = t['statut'] ?? '';
            final date = t['date_depart'] ?? '';
            return DataRow(
              cells: [
                DataCell(Text(date.isNotEmpty
                    ? DateFormat('dd/MM/yyyy HH:mm')
                        .format(DateTime.tryParse(date) ?? DateTime.now())
                    : '')),
                DataCell(Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        conducteurNom,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                )),
                DataCell(Row(
                  children: [
                    const Icon(Icons.directions_car, size: 16),
                    const SizedBox(width: 6),
                    Text(vehicule),
                  ],
                )),
                DataCell(Text(depart)),
                DataCell(Text(arrivee)),
                DataCell(Text('$distance km')),
                DataCell(Text(raison)),
                DataCell(_buildStatutBadge(statut)),
                DataCell(IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Voir le détail',
                  onPressed: () => onSelect(t),
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatutBadge(String statut) {
    Color color;
    switch (statut) {
      case 'terminee':
        color = Colors.green.shade600;
        break;
      case 'active':
        color = Colors.blue.shade700;
        break;
      case 'acceptee':
        color = Colors.orange.shade700;
        break;
      case 'refusee':
        color = Colors.red.shade600;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(statut,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

// --- Carte interactive (Google Maps) ---
class _TrajetMapWidget extends StatelessWidget {
  final Map<String, dynamic>? trajet;
  const _TrajetMapWidget({this.trajet});

  @override
  Widget build(BuildContext context) {
    if (trajet == null) {
      return Card(
        margin: const EdgeInsets.all(16),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: const Text('Sélectionnez un trajet pour voir la carte',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    // Extraction des coordonnées GPS du trajet
    final departLat =
        double.tryParse(trajet!['depart_latitude']?.toString() ?? '');
    final departLng =
        double.tryParse(trajet!['depart_longitude']?.toString() ?? '');
    final arriveeLat =
        double.tryParse(trajet!['arrivee_latitude']?.toString() ?? '');
    final arriveeLng =
        double.tryParse(trajet!['arrivee_longitude']?.toString() ?? '');
    if (departLat == null ||
        departLng == null ||
        arriveeLat == null ||
        arriveeLng == null) {
      return Card(
        margin: const EdgeInsets.all(16),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 300,
          alignment: Alignment.center,
          child: const Text('Coordonnées GPS manquantes pour ce trajet',
              style: TextStyle(color: Colors.red)),
        ),
      );
    }
    final depart = gmaps.LatLng(departLat, departLng);
    final arrivee = gmaps.LatLng(arriveeLat, arriveeLng);
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 300,
        child: gmaps.GoogleMap(
          initialCameraPosition: gmaps.CameraPosition(
            target: depart,
            zoom: 12,
          ),
          markers: {
            gmaps.Marker(
              markerId: const gmaps.MarkerId('depart'),
              position: depart,
              infoWindow: const gmaps.InfoWindow(title: 'Départ'),
            ),
            gmaps.Marker(
              markerId: const gmaps.MarkerId('arrivee'),
              position: arrivee,
              infoWindow: const gmaps.InfoWindow(title: 'Arrivée'),
            ),
          },
          polylines: {
            gmaps.Polyline(
              polylineId: const gmaps.PolylineId('trajet'),
              points: [depart, arrivee],
              color: Colors.blue,
              width: 5,
            ),
          },
        ),
      ),
    );
  }
}

// --- Drawer de détail (placeholder) ---
class _TrajetDetailDrawer extends StatelessWidget {
  final Map<String, dynamic> trajet;
  const _TrajetDetailDrawer({required this.trajet});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Détail du trajet',
                    style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const Divider(),
            Text(
                'Conducteur : ${trajet['driver_details']?['user']?['username'] ?? ''}'),
            Text('Véhicule : ${trajet['vehicle_details']?['plaque'] ?? ''}'),
            Text('Départ : ${trajet['lieu_depart'] ?? ''}'),
            Text('Arrivée : ${trajet['lieu_arrivee'] ?? ''}'),
            Text('Distance : ${trajet['distance_km'] ?? ''} km'),
            Text('Raison : ${trajet['raison'] ?? ''}'),
            Text('Statut : ${trajet['statut'] ?? ''}'),
            const SizedBox(height: 24),
            const Text(
                '(à intégrer : carte, liste des positions GPS, export PDF, etc.)',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class TrajetsLivePage extends StatefulWidget {
  const TrajetsLivePage({Key? key}) : super(key: key);

  @override
  State<TrajetsLivePage> createState() => _TrajetsLivePageState();
}

class _TrajetsLivePageState extends State<TrajetsLivePage> {
  List<Map<String, dynamic>> conducteurs = [];
  bool isLoading = true;
  int? selectedConducteurId;
  int selectedTrajetIndex = 0;
  bool showConnectedOnly = false;

  // Ajout pour l'historique
  List<latlng.LatLng> historiquePositions = [];
  bool isLoadingHistorique = false;
  List<Map<String, dynamic>> historiqueRaw = [];

  @override
  void initState() {
    super.initState();
    fetchConducteursEtPositions();
  }

  Future<void> fetchConducteursEtPositions() async {
    setState(() {
      isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      final driversResp = await http.get(
        Uri.parse('http://localhost:8000/api/drivers/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (driversResp.statusCode != 200) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      final List drivers = jsonDecode(driversResp.body);
      List<Map<String, dynamic>> result = [];
      for (final d in drivers) {
        final id = d['id'];
        final name =
            d['user_profile']?['user']?['username'] ?? 'Conducteur $id';
        final posResp = await http.get(
          Uri.parse('http://localhost:8000/api/positions/last/$id/'),
          headers: {'Authorization': 'Bearer $token'},
        );
        latlng.LatLng? position;
        bool enLigne = false;
        DateTime? lastTime;
        if (posResp.statusCode == 200 && posResp.body.isNotEmpty) {
          final pos = jsonDecode(posResp.body);
          if (pos['latitude'] != null && pos['longitude'] != null) {
            position = latlng.LatLng(
              double.tryParse(pos['latitude'].toString()) ?? 0.0,
              double.tryParse(pos['longitude'].toString()) ?? 0.0,
            );
            if (pos['timestamp'] != null) {
              lastTime = DateTime.tryParse(pos['timestamp']);
              if (lastTime != null &&
                  DateTime.now().difference(lastTime).inMinutes < 2) {
                enLigne = true;
              }
            }
          }
        }
        result.add({
          'id': id,
          'nom': name,
          'en_ligne': enLigne,
          'position': position ?? latlng.LatLng(0, 0),
          'trajets': [],
          'lastTime': lastTime,
        });
      }
      setState(() {
        conducteurs = result;
        isLoading = false;
        if (conducteurs.isNotEmpty && selectedConducteurId == null) {
          selectedConducteurId = conducteurs.first['id'];
        }
      });
      // Charger l'historique du conducteur sélectionné
      if (conducteurs.isNotEmpty) {
        await fetchHistoriquePositions(
            selectedConducteurId ?? conducteurs.first['id']);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchHistoriquePositions(int conducteurId) async {
    setState(() {
      isLoadingHistorique = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() {
          isLoadingHistorique = false;
        });
        return;
      }
      final resp = await http.get(
        Uri.parse('http://localhost:8000/api/positions/?driver=$conducteurId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        historiquePositions = data
            .map<latlng.LatLng>((p) => latlng.LatLng(
                  double.tryParse(p['latitude'].toString()) ?? 0.0,
                  double.tryParse(p['longitude'].toString()) ?? 0.0,
                ))
            .toList();
        historiqueRaw = data.cast<Map<String, dynamic>>();
      } else {
        historiquePositions = [];
        historiqueRaw = [];
      }
      setState(() {
        isLoadingHistorique = false;
      });
    } catch (e) {
      setState(() {
        isLoadingHistorique = false;
      });
    }
  }

  void onSelectConducteur(int id) async {
    setState(() {
      selectedConducteurId = id;
      selectedTrajetIndex = 0;
      isLoadingHistorique = true;
    });
    await fetchHistoriquePositions(id);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final selectedConducteur = conducteurs.firstWhere(
      (c) => c['id'] == selectedConducteurId,
      orElse: () =>
          conducteurs.isNotEmpty ? conducteurs.first : <String, dynamic>{},
    );
    final stats = _computeStats();
    final List<Map<String, dynamic>> conducteursEnLigne =
        conducteurs.where((c) => c['en_ligne'] == true).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi en direct des trajets'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: fetchConducteursEtPositions,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Tous les conducteurs'),
                selected: !showConnectedOnly,
                onSelected: (v) => setState(() => showConnectedOnly = false),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Conducteurs connectés'),
                selected: showConnectedOnly,
                onSelected: (v) => setState(() => showConnectedOnly = true),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF7F9FB),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : isMobile
              ? Column(
                  children: [
                    _StatsBar(stats: stats),
                    Expanded(
                      child: _LiveMap(
                        conducteurs: showConnectedOnly
                            ? conducteursEnLigne
                            : conducteurs,
                        selectedId: selectedConducteurId,
                        selectedTrajetIndex: selectedTrajetIndex,
                        onSelect: (id) => onSelectConducteur(id),
                        historiquePositions: historiquePositions,
                      ),
                    ),
                    SizedBox(
                      height: 220,
                      child: _ConducteursPanel(
                        conducteurs: showConnectedOnly
                            ? conducteursEnLigne
                            : conducteurs,
                        selectedId: selectedConducteurId,
                        onSelect: (id) => onSelectConducteur(id),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 280,
                      child: _ConducteursPanel(
                        conducteurs: showConnectedOnly
                            ? conducteursEnLigne
                            : conducteurs,
                        selectedId: selectedConducteurId,
                        onSelect: (id) => onSelectConducteur(id),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _StatsBar(stats: stats),
                          Expanded(
                            child: _LiveMap(
                              conducteurs: showConnectedOnly
                                  ? conducteursEnLigne
                                  : conducteurs,
                              selectedId: selectedConducteurId,
                              selectedTrajetIndex: selectedTrajetIndex,
                              onSelect: (id) => onSelectConducteur(id),
                              historiquePositions: historiquePositions,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 350,
                      child: _HistoriquePanel(
                        conducteur: selectedConducteur,
                        isLoading: isLoadingHistorique,
                        historiqueRaw: historiqueRaw,
                      ),
                    ),
                  ],
                ),
    );
  }

  Map<String, dynamic> _computeStats() {
    final enLigne = conducteurs.where((c) => c['en_ligne'] == true).length;
    final total = conducteurs.length;
    // total_km à calculer dynamiquement plus tard
    return {
      'en_ligne': enLigne,
      'total': total,
      'total_km': 0.0,
    };
  }
}

class _LiveMap extends StatelessWidget {
  final List<Map<String, dynamic>> conducteurs;
  final int? selectedId;
  final int selectedTrajetIndex;
  final ValueChanged<int> onSelect;
  final List<latlng.LatLng> historiquePositions;
  const _LiveMap(
      {required this.conducteurs,
      required this.selectedId,
      required this.selectedTrajetIndex,
      required this.onSelect,
      required this.historiquePositions});
  @override
  Widget build(BuildContext context) {
    final selectedConducteur = conducteurs.firstWhere(
      (c) => c['id'] == selectedId,
      orElse: () =>
          conducteurs.isNotEmpty ? conducteurs.first : <String, dynamic>{},
    );
    // Conversion des positions pour Google Maps
    final gmaps.LatLng defaultCenter = gmaps.LatLng(5.34539, -4.02441);
    final gmaps.LatLng center = (selectedConducteur['position'] != null)
        ? gmaps.LatLng(selectedConducteur['position'].latitude,
            selectedConducteur['position'].longitude)
        : defaultCenter;
    final Set<gmaps.Marker> markers = conducteurs
        .map((c) {
          final isSelected = c['id'] == selectedId;
          final pos = c['position'];
          if (pos == null) return null;
          return gmaps.Marker(
            markerId: gmaps.MarkerId('conducteur_${c['id']}'),
            position: gmaps.LatLng(pos.latitude, pos.longitude),
            icon: isSelected
                ? gmaps.BitmapDescriptor.defaultMarkerWithHue(
                    gmaps.BitmapDescriptor.hueBlue)
                : gmaps.BitmapDescriptor.defaultMarker,
            infoWindow: gmaps.InfoWindow(title: c['nom'] ?? ''),
            onTap: () => onSelect(c['id']),
          );
        })
        .whereType<gmaps.Marker>()
        .toSet();
    final List<gmaps.LatLng> polylinePoints = historiquePositions
        .map((p) => gmaps.LatLng(p.latitude, p.longitude))
        .toList();
    final Set<gmaps.Polyline> polylines = polylinePoints.isNotEmpty
        ? {
            gmaps.Polyline(
              polylineId: const gmaps.PolylineId('historique'),
              points: polylinePoints,
              color: Colors.blue,
              width: 5,
            ),
          }
        : {};
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 400,
        child: gmaps.GoogleMap(
          initialCameraPosition: gmaps.CameraPosition(
            target: center,
            zoom: 13.0,
          ),
          markers: markers,
          polylines: polylines,
          onTap: (_) {},
        ),
      ),
    );
  }
}

class _HistoriquePanel extends StatelessWidget {
  final Map<String, dynamic> conducteur;
  final bool isLoading;
  final List<Map<String, dynamic>> historiqueRaw;
  const _HistoriquePanel(
      {required this.conducteur,
      required this.isLoading,
      required this.historiqueRaw});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Historique de ${conducteur['nom']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Icon(Icons.history, color: Colors.blue.shade700),
              ],
            ),
            const Divider(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: historiqueRaw.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final t = historiqueRaw[i];
                        return ListTile(
                          leading: const Icon(Icons.route, color: Colors.blue),
                          title: Text('Point du ${t['timestamp'] ?? ''}'),
                          subtitle: Text(
                              'Lat: ${t['latitude']}, Lng: ${t['longitude']}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsBar({required this.stats});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatCard(
              icon: Icons.people,
              label: 'Conducteurs',
              value: '${stats['total']}',
              color: Colors.blue),
          _StatCard(
              icon: Icons.wifi,
              label: 'En ligne',
              value: '${stats['en_ligne']}',
              color: Colors.green),
          _StatCard(
              icon: Icons.straighten,
              label: 'Km aujourd\'hui',
              value: '${stats['total_km'].toStringAsFixed(1)}',
              color: Colors.orange),
        ],
      ),
    );
  }
}

class _ConducteursPanel extends StatelessWidget {
  final List<Map<String, dynamic>> conducteurs;
  final int? selectedId;
  final ValueChanged<int> onSelect;
  const _ConducteursPanel(
      {required this.conducteurs,
      required this.selectedId,
      required this.onSelect});
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListView.separated(
        itemCount: conducteurs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final c = conducteurs[i];
          final user = c['user_profile']?['user'];
          String conducteurNom = '';
          if (user != null) {
            conducteurNom = [user['first_name'] ?? '', user['last_name'] ?? '']
                .where((e) => e.isNotEmpty)
                .join(' ')
                .trim();
            if (conducteurNom.isEmpty) {
              conducteurNom = user['username'] ?? '';
            }
          } else {
            conducteurNom = c['nom'] ?? '';
          }
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: c['en_ligne'] ? Colors.green : Colors.grey,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              conducteurNom,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: c['en_ligne']
                ? const Icon(Icons.wifi, color: Colors.green, size: 20)
                : null,
            selected: c['id'] == selectedId,
            onTap: () => onSelect(c['id']),
          );
        },
      ),
    );
  }
}

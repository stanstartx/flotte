import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flotte/widgets/menu_admin/admin_menu.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class TableauDeBordAdmin extends StatefulWidget {
  const TableauDeBordAdmin({super.key});

  @override
  State<TableauDeBordAdmin> createState() => _TableauDeBordAdminState();
}

class _TableauDeBordAdminState extends State<TableauDeBordAdmin> {
  Map<String, dynamic> dashboardData = {};
  List<dynamic> vehicles = [];
  List<dynamic> drivers = [];
  Map<String, int> vehiclesByType = {};
  List<dynamic> recentVehicles = [];
  List<dynamic> recentDrivers = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          errorMessage = 'Token d\'authentification non trouvé';
          isLoading = false;
        });
        return;
      }

      // Fetch stats
      final statsResponse = await http.get(
        Uri.parse('http://192.168.11.243:8000/api/dashboard/stats/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Fetch vehicles
      final vehiclesResponse = await http.get(
        Uri.parse('http://192.168.11.243:8000/api/vehicles/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Fetch drivers
      final driversResponse = await http.get(
        Uri.parse('http://192.168.11.243:8000/api/drivers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (statsResponse.statusCode == 200 && vehiclesResponse.statusCode == 200 && driversResponse.statusCode == 200) {
        final statsData = json.decode(statsResponse.body);
        final vehiclesData = json.decode(vehiclesResponse.body);
        final driversData = json.decode(driversResponse.body);

        print("Données API Stats: $statsData");
        print("Données API Vehicles: $vehiclesData");
        print("Données API Drivers: $driversData");

        // Process vehicles by type
        vehiclesByType = <String, int>{};
        for (var vehicle in vehiclesData is List ? vehiclesData : (vehiclesData['results'] ?? [])) {
          final type = vehicle['type_vehicule']?.toString() ?? 'Inconnu';
          vehiclesByType[type] = (vehiclesByType[type] ?? 0) + 1;
        }

        // Recent vehicles (last 5, sorted by id descending assuming id is creation order)
        recentVehicles = (vehiclesData is List ? vehiclesData : (vehiclesData['results'] ?? []))
            .take(5)
            .toList();

        // Recent drivers (last 5)
        recentDrivers = (driversData is List ? driversData : (driversData['results'] ?? []))
            .take(5)
            .toList();

        setState(() {
          dashboardData = statsData;
          vehicles = vehiclesData is List ? vehiclesData : (vehiclesData['results'] ?? []);
          drivers = driversData is List ? driversData : (driversData['results'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Erreur lors du chargement: Stats(${statsResponse.statusCode}), Vehicles(${vehiclesResponse.statusCode}), Drivers(${driversResponse.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de connexion: $e';
        isLoading = false;
      });
      print("Erreur récupération données dashboard: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FC),
          drawer: isMobile ? const AdminMenu() : null,
          bottomNavigationBar: isMobile ? const MobileNavigationBar() : null,
          body: Row(
            children: [
              if (!isMobile)
                SizedBox(
                  width: 240,
                  child: const AdminMenu(),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Tableau de bord - ADMINISTRATEUR",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF002244),
                              ),
                            ),
                            IconButton(
                              onPressed: fetchDashboardData,
                              icon: const Icon(Icons.refresh),
                              tooltip: 'Actualiser',
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // -------- Gestion des erreurs et chargement
                        if (errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.red.shade600),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(() => errorMessage = null),
                                  icon: Icon(Icons.close, color: Colors.red.shade600),
                                ),
                              ],
                            ),
                          ),

                        // -------- KPIs
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Wrap(
                                spacing: 20,
                                runSpacing: 20,
                                children: [
                                  StatCard(
                                    icon: Icons.directions_car,
                                    label: "Total véhicules",
                                    value: (dashboardData['vehicles']?['total'] ?? 0).toString(),
                                    subtitle: "${dashboardData['vehicles']?['active'] ?? 0} actifs",
                                    color: const Color(0xFFE9F1FC),
                                    iconColor: const Color(0xFF003366),
                                  ),
                                  StatCard(
                                    icon: Icons.person,
                                    label: "Total conducteurs",
                                    value: (dashboardData['drivers']?['total'] ?? 0).toString(),
                                    subtitle: "${dashboardData['drivers']?['active'] ?? 0} actifs",
                                    color: const Color(0xFFF1F5F9),
                                    iconColor: const Color(0xFF003366),
                                  ),
                                  StatCard(
                                    icon: Icons.assignment,
                                    label: "Total missions",
                                    value: (dashboardData['missions']?['total'] ?? 0).toString(),
                                    subtitle: "${dashboardData['missions']?['pending'] ?? 0} en attente",
                                    color: const Color(0xFFE8F5E8),
                                    iconColor: const Color(0xFF2E7D32),
                                  ),
                                  StatCard(
                                    icon: Icons.warning,
                                    label: "Alertes critiques",
                                    value: (dashboardData['alerts']?['critical'] ?? dashboardData['alerts']?['critical Ascertainable'] ?? 0).toString(),
                                    subtitle: "${dashboardData['alerts']?['total'] ?? 0} total",
                                    color: const Color(0xFFFFF3E0),
                                    iconColor: const Color(0xFFF57C00),
                                  ),
                                ],
                              ),

                        const SizedBox(height: 32),

                        // -------- QUICK ACTIONS
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _quickAction(Icons.add_circle, "Ajouter véhicule",
                                () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const VehiculeFormDialog(),
                                  );
                                }),
                            _quickAction(Icons.person_add, "Ajouter conducteur",
                                () {
                                  // TODO : ouvrir formulaire conducteur
                                  // Exemple: showDialog(context: context, builder: (_) => const ConducteurFormDialog());
                                }),
                            _quickAction(Icons.assignment, "Nouvelle mission",
                                () {
                                  // TODO : ouvrir formulaire mission
                                }),
                            _quickAction(Icons.warning, "Voir alertes", () {
                              // TODO : rediriger vers la page alertes
                            }),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // -------- GRAPH (répartition véhicules par type)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Répartition des véhicules par type",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF003366),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 300,
                                  child: vehiclesByType.isEmpty
                                      ? const Center(child: Text("Aucune donnée disponible"))
                                      : BarChart(
                                          BarChartData(
                                            alignment: BarChartAlignment.spaceAround,
                                            maxY: (vehiclesByType.values.reduce((a, b) => a + b) * 1.2).toDouble(),
                                            barTouchData: BarTouchData(enabled: false),
                                            titlesData: FlTitlesData(
                                              show: true,
                                              bottomTitles: AxisTitles(
                                                sideTitles: SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget: (double value, TitleMeta meta) {
                                                    final index = value.toInt();
                                                    final keys = vehiclesByType.keys.toList();
                                                    return index >= 0 && index < keys.length
                                                        ? SideTitleWidget(
                                                            axisSide: meta.axisSide,
                                                            space: 8,
                                                            child: Text(keys[index], style: GoogleFonts.poppins(fontSize: 12)),
                                                          )
                                                        : const SizedBox.shrink();
                                                  },
                                                  reservedSize: 30,
                                                ),
                                              ),
                                              leftTitles: AxisTitles(
                                                sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                                              ),
                                            ),
                                            borderData: FlBorderData(show: false),
                                            gridData: FlGridData(show: true),
                                            barGroups: vehiclesByType.entries.toList().asMap().entries.map((entry) {
                                              return BarChartGroupData(
                                                x: entry.key,
                                                barRods: [
                                                  BarChartRodData(
                                                    toY: entry.value.value.toDouble(),
                                                    color: const Color(0xFF003366),
                                                    width: 16,
                                                    borderRadius: BorderRadius.circular(4),
                                                    backDrawRodData: BackgroundBarChartRodData(
                                                      show: true,
                                                      toY: (vehiclesByType.values.reduce((a, b) => a + b) * 1.2).toDouble(),
                                                      color: Colors.grey[200],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // -------- VEHICULES RECENTS
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Véhicules récents",
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF003366),
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => const VehiculeFormDialog(),
                                        );
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text("Ajouter"),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                recentVehicles.isEmpty
                                    ? const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text("Aucun véhicule récent trouvé."),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: recentVehicles.length,
                                        itemBuilder: (context, index) {
                                          final vehicule = recentVehicles[index];
                                          final status = _getStatusText(vehicule);
                                          return Card(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            child: ListTile(
                                              leading: const Icon(Icons.directions_car, color: Color(0xFF003366)),
                                              title: Text("${vehicule['marque'] ?? 'N/A'} ${vehicule['modele'] ?? ''}", style: GoogleFonts.poppins(fontSize: 14)),
                                              subtitle: Text("Matricule: ${vehicule['immatriculation'] ?? 'N/A'}", style: GoogleFonts.poppins(fontSize: 12)),
                                              trailing: Chip(
                                                label: Text(status),
                                                backgroundColor: _getStatusColor(status).withOpacity(0.2),
                                                labelStyle: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // -------- CONDUCTEURS RECENTS
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Conducteurs récents",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF003366),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                recentDrivers.isEmpty
                                    ? const Text("Aucun conducteur récent trouvé.")
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        itemCount: recentDrivers.length,
                                        itemBuilder: (context, index) {
                                          final conducteur = recentDrivers[index];
                                          final prenom = conducteur['user_profile']?['user']?['first_name'] ?? 'N/A';
                                          final nom = conducteur['user_profile']?['user']?['last_name'] ?? '';
                                          final tel = conducteur['user_profile']?['telephone'] ?? "N/A";
                                          final statut = conducteur['statut'] ?? "N/A";
                                          return Card(
                                            margin: const EdgeInsets.only(bottom: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            child: ListTile(
                                              leading: CircleAvatar(
                                                backgroundColor: Colors.grey[200],
                                                child: Text(prenom.isNotEmpty ? prenom[0] : "?", style: GoogleFonts.poppins(color: Color(0xFF003366))),
                                              ),
                                              title: Text("$prenom $nom", style: GoogleFonts.poppins(fontSize: 14)),
                                              subtitle: Text("Tel: $tel", style: GoogleFonts.poppins(fontSize: 12)),
                                              trailing: Chip(
                                                label: Text(statut),
                                                backgroundColor: _getStatusColor(statut).withOpacity(0.2),
                                                labelStyle: TextStyle(color: _getStatusColor(statut), fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: const Color(0xFF003366)),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF003366))),
          ],
        ),
      ),
    );
  }

  String _getStatusText(dynamic item) {
    if (item['actif'] == true) return "En service";
    if (item['actif'] == false) return "Inactif";
    return "Maintenance";
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "en service":
        return Colors.green;
      case "inactif":
        return Colors.red;
      case "maintenance":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// ---------------- STAT CARD ----------------
class StatCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;
  final Color iconColor;
  final Color textColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
    required this.iconColor,
    this.textColor = const Color(0xFF002244),
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isHovered ? widget.color.withOpacity(0.85) : widget.color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isHovered
              ? [const BoxShadow(color: Colors.black12, blurRadius: 8)]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(widget.icon, color: widget.iconColor, size: 30),
            const SizedBox(height: 12),
            Text(widget.label,
                style: GoogleFonts.poppins(fontSize: 12, color: widget.textColor)),
            Text(widget.value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: widget.textColor,
                )),
            if (widget.subtitle != null)
              Text(
                widget.subtitle!,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: widget.textColor.withOpacity(0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------- MOBILE NAV BAR ----------------
class MobileNavigationBar extends StatelessWidget {
  const MobileNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      selectedItemColor: const Color(0xFF003366),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Tableau"),
        BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: "Véhicules"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Conducteurs"),
        BottomNavigationBarItem(icon: Icon(Icons.warning), label: "Alertes"),
      ],
    );
  }
}

// ---------------- MODAL VEHICULE ----------------
class VehiculeFormDialog extends StatefulWidget {
  const VehiculeFormDialog({super.key});
  @override
  State<VehiculeFormDialog> createState() => _VehiculeFormDialogState();
}

class _VehiculeFormDialogState extends State<VehiculeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _immatriculationController = TextEditingController();
  String _typeVehicule = 'Voiture';
  bool _actif = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _marqueController.dispose();
    _modeleController.dispose();
    _immatriculationController.dispose();
    super.dispose();
  }

  Future<void> _submitVehicule() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final payload = {
      "marque": _marqueController.text.trim(),
      "modele": _modeleController.text.trim(),
      "immatriculation": _immatriculationController.text.trim(),
      "type_vehicule": _typeVehicule,
      "actif": _actif,
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // Exemple d'envoi au backend (décommenter et adapter l'URL)
      // final res = await http.post(
      //   Uri.parse('http://192.168.11.243:8000/api/vehicles/'),
      //   headers: headers,
      //   body: json.encode(payload),
      // );
      // if (res.statusCode == 201) {
      //   Navigator.pop(context, true);
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${res.body}')));
      // }

      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter / Modifier un véhicule'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _marqueController,
                decoration: const InputDecoration(labelText: 'Marque'),
                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _modeleController,
                decoration: const InputDecoration(labelText: 'Modèle'),
                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _immatriculationController,
                decoration: const InputDecoration(labelText: 'Immatriculation'),
                validator: (value) => (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _typeVehicule,
                items: const [
                  DropdownMenuItem(value: 'Voiture', child: Text('Voiture')),
                  DropdownMenuItem(value: 'Camion', child: Text('Camion')),
                  DropdownMenuItem(value: 'Moto', child: Text('Moto')),
                  DropdownMenuItem(value: 'Utilitaire', child: Text('Utilitaire')),
                ],
                onChanged: (value) => setState(() => _typeVehicule = value!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Actif'),
                value: _actif,
                onChanged: (value) => setState(() => _actif = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitVehicule,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
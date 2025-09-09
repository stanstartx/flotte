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

      final response = await http.get(
        Uri.parse('http://192.168.11.243:8000/api/dashboard/stats/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          dashboardData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Erreur ${response.statusCode}: ${response.reasonPhrase}';
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
          drawer: isMobile ? AdminMenu() : null,
          bottomNavigationBar: isMobile ? const MobileNavigationBar() : null,
          body: Row(
            children: [
              if (!isMobile) AdminMenu(),
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
                                    value: (dashboardData['alerts']?['critical'] ?? 0).toString(),
                                    subtitle: "${dashboardData['alerts']?['total'] ?? 0} total",
                                    color: const Color(0xFFFFF3E0),
                                    iconColor: const Color(0xFFF57C00),
                                  ),
                                  StatCard(
                                    icon: Icons.euro,
                                    label: "Dépenses (30j)",
                                    value: "${(dashboardData['finances']?['recent_expenses'] ?? 0.0).toStringAsFixed(0)}€",
                                    subtitle: "Carburant: ${(dashboardData['finances']?['recent_fuel'] ?? 0.0).toStringAsFixed(0)}€",
                                    color: const Color(0xFFFCE4EC),
                                    iconColor: const Color(0xFFC2185B),
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
                                  builder: (_) => const VehiculeFormDialog());
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

                        // -------- GRAPH (répartition véhicules)
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
                                  height: 200,
                                  child: dashboardData['vehicles']?['by_type']?.isEmpty ?? true
                                      ? const Center(
                                          child: Text("Aucune donnée"))
                                      : PieChart(
                                          PieChartData(
                                            sections: (dashboardData['vehicles']?['by_type'] as Map<String, int>).entries
                                                .map(
                                                  (e) => PieChartSectionData(
                                                    value: e.value.toDouble(),
                                                    title:
                                                        '${e.key} (${e.value})',
                                                    radius: 50,
                                                    titleStyle: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                            sectionsSpace: 4,
                                            centerSpaceRadius: 24,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // -------- TABLE VEHICULES
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                          builder: (_) =>
                                              const VehiculeFormDialog(),
                                        );
                                      },
                                      icon: const Icon(Icons.add),
                                      label: const Text("Ajouter"),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                dashboardData['vehicles']?['recent']?.isEmpty ?? true
                                    ? const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text("Aucun véhicule trouvé."),
                                      )
                                    : VehiculeTable(
                                        vehicules: dashboardData['vehicles']?['recent'] as List<dynamic>),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // -------- LIST CONDUCTEURS
                        _buildConducteursList(),
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

  Widget _buildConducteursList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            dashboardData['drivers']?['recent']?.isEmpty ?? true
                ? const Text("Aucun conducteur à afficher.")
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (dashboardData['drivers']?['recent'] as List<dynamic>)?.length ?? 0,
                    itemBuilder: (context, index) {
                      final conducteur = (dashboardData['drivers']?['recent'] as List<dynamic>)?[index];
                      final prenom = conducteur['user_profile']?['user']
                              ?['first_name'] ??
                          '';
                      final nom = conducteur['user_profile']?['user']
                              ?['last_name'] ??
                          '';
                      final tel =
                          conducteur['user_profile']?['telephone'] ?? "N/A";
                      final statut = conducteur['statut'] ?? "N/A";

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: Text(prenom.isNotEmpty ? prenom[0] : "?"),
                        ),
                        title: Text("$prenom $nom"),
                        subtitle: Text(tel),
                        trailing: Chip(
                          label: Text(statut),
                          backgroundColor:
                              _getStatusColor(statut).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _getStatusColor(statut),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case "actif":
        return Colors.green;
      case "inactif":
        return Colors.red;
      case "en congé":
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
                style:
                    GoogleFonts.poppins(fontSize: 12, color: widget.textColor)),
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

// ---------------- TABLE VEHICULES ----------------
class VehiculeTable extends StatelessWidget {
  final List<dynamic> vehicules;
  const VehiculeTable({super.key, required this.vehicules});

  String _getStatusText(dynamic vehicule) {
    if (vehicule['actif'] == true) return "En service";
    if (vehicule['actif'] == false) return "Inactif";
    return "Maintenance";
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "En service":
        return Colors.green;
      case "Inactif":
        return Colors.red;
      case "Maintenance":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Marque")),
            DataColumn(label: Text("Modèle")),
            DataColumn(label: Text("Immatriculation")),
            DataColumn(label: Text("Statut")),
            DataColumn(label: Text("Type")),
          ],
          rows: vehicules.map((v) {
            final status = _getStatusText(v);
            return DataRow(
              cells: [
                DataCell(Text(v['marque'] ?? "N/A")),
                DataCell(Text(v['modele'] ?? "N/A")),
                DataCell(Text(v['immatriculation'] ?? "N/A")),
                DataCell(Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(status,
                      style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w500)),
                )),
                DataCell(Text(v['type_vehicule'] ?? "N/A")),
              ],
            );
          }).toList(),
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
        BottomNavigationBarItem(
            icon: Icon(Icons.directions_car), label: "Véhicules"),
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
      //   Uri.parse('http://localhost:8000/api/vehicles/'),
      //   headers: headers,
      //   body: json.encode(payload),
      // );
      // if (res.statusCode == 201) { // ou 200 selon ton API
      //   // succès: fermer et rafraîchir si besoin
      //   Navigator.pop(context, true);
      // } else {
      //   // gérer l'erreur
      //   final err = res.body;
      //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $err')));
      // }

      // Pour l'instant on ferme la modale et renvoie true pour indiquer succès
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _modeleController,
                decoration: const InputDecoration(labelText: 'Modèle'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _immatriculationController,
                decoration: const InputDecoration(labelText: 'Immatriculation'),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _typeVehicule,
                items: const [
                  DropdownMenuItem(value: 'Voiture', child: Text('Voiture')),
                  DropdownMenuItem(value: 'Camion', child: Text('Camion')),
                  DropdownMenuItem(value: 'Moto', child: Text('Moto')),
                  DropdownMenuItem(
                      value: 'Utilitaire', child: Text('Utilitaire')),
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

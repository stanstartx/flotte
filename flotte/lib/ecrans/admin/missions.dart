import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flotte/widgets/menu_admin/admin_menu.dart';
import 'package:flotte/models/mission.dart';
import 'package:flotte/services/mission_service.dart';
import 'package:flotte/widgets/mission_form.dart';
import 'dart:async';

class MissionsPage extends StatefulWidget {
  const MissionsPage({super.key});

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  String searchQuery = '';
  String selectedStatut = 'Tous';
  final List<String> statuts = ['Tous', 'En cours', 'Terminée', 'Planifiée'];
  final MissionService _missionService = MissionService();
  List<Mission> _missions = [];
  bool _isLoading = true;
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMissions();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _loadMissions();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMissions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      List<Mission> missions;
      if (selectedStatut == 'Tous') {
        missions = await _missionService.getMissions();
      } else {
        final statusMap = {
          'En cours': 'en_cours',
          'Terminée': 'terminee',
          'Planifiée': 'planifiee',
        };
        missions = await _missionService.getMissionsByStatus(
            statusMap[selectedStatut] ?? selectedStatut.toLowerCase());
      }

      if (searchQuery.isNotEmpty) {
        missions = missions.where((mission) {
          final query = searchQuery.toLowerCase();
          return mission.codeMission.toLowerCase().contains(query) ||
              mission.intitule.toLowerCase().contains(query) ||
              mission.lieuDepart.toLowerCase().contains(query) ||
              mission.lieuArrivee.toLowerCase().contains(query);
        }).toList();
      }

      setState(() {
        _missions = missions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openMissionDialog({Mission? mission}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: MissionForm(
              mission: mission,
              onSubmit: (m) async {
                try {
                  if (mission == null) {
                    await _missionService.createMission(m);
                  } else {
                    await _missionService.updateMission(m);
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                    _loadMissions();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(mission == null
                            ? 'Mission créée avec succès'
                            : 'Mission mise à jour avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Mission mission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer cette mission ?\nCette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _missionService.deleteMission(mission.id);
                if (mounted) {
                  Navigator.of(context).pop();
                  _loadMissions();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mission supprimée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Intitulé')),
            DataColumn(label: Text('Conducteur')),
            DataColumn(label: Text('Véhicule')),
            DataColumn(label: Text('Statut')),
            DataColumn(label: Text('Actions')),
          ],
          rows: _missions.map((mission) {
            final conducteur = mission.driverDetails;
            final vehicule = mission.vehicleDetails;

            final conducteurNom =
                "${conducteur?['user_profile']?['user']?['first_name'] ?? ''} "
                "${conducteur?['user_profile']?['user']?['last_name'] ?? ''}";

            final vehiculeNom =
                "${vehicule?['marque'] ?? ''} ${vehicule?['modele'] ?? ''}";

            return DataRow(cells: [
              DataCell(Text(mission.codeMission)),
              DataCell(Text(mission.intitule)),
              DataCell(
                  Text(conducteurNom.trim().isEmpty ? '-' : conducteurNom)),
              DataCell(Text(vehiculeNom.trim().isEmpty ? '-' : vehiculeNom)),
              DataCell(Text(mission.statut ?? '')),
              DataCell(Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                    onPressed: () => _openMissionDialog(mission: mission),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () => _openMissionDialog(mission: mission),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(mission),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bool isMobile = constraints.maxWidth < 700;

      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
        drawer: isMobile ? const AdminMenu() : null,
        appBar: isMobile
            ? AppBar(
                title: Text(
                  'Missions',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                ),
                backgroundColor: const Color(0xFF002244),
                iconTheme: const IconThemeData(color: Colors.white),
              )
            : null,
        body: Row(
          children: [
            if (!isMobile) const AdminMenu(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMobile)
                      Text(
                        'Gestion des Missions',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF002244),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Filtres et recherche
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 240,
                              child: TextField(
                                onChanged: (v) {
                                  setState(() => searchQuery = v);
                                  _loadMissions();
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Rechercher',
                                  hintText: 'Code, conducteur, véhicule...',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 200,
                              child: DropdownButtonFormField<String>(
                                value: selectedStatut,
                                onChanged: (v) {
                                  setState(() => selectedStatut = v!);
                                  _loadMissions();
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Statut',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                items: statuts
                                    .map((e) => DropdownMenuItem(
                                        value: e, child: Text(e)))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ajouter mission
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _openMissionDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text("Nouvelle mission"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF002244),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _missions.isEmpty
                              ? const Center(
                                  child: Text('Aucune mission trouvée'))
                              : _buildMissionTable(),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

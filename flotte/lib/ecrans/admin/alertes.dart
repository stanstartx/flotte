import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flotte/widgets/menu_admin/admin_menu.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flotte/services/notification_service.dart';
import 'package:flotte/services/sms_service.dart';
import 'package:flotte/services/email_service.dart';

class AlertesPage extends StatefulWidget {
  const AlertesPage({super.key});

  @override
  State<AlertesPage> createState() => _AlertesPageState();
}

class _AlertesPageState extends State<AlertesPage> {
  String searchQuery = '';
  String selectedType = 'Tous';
  List<dynamic> alertes = [];
  bool isLoading = true;
  bool showResolved = false;

  final List<String> typesAlertes = [
    'Tous',
    'entretien',
    'assurance',
    'controle_technique',
    'permis',
    'autre',
  ];

  final NotificationService _notificationService = NotificationService();
  final SMSService _smsService = SMSService();
  final EmailService _emailService = EmailService();

  @override
  void initState() {
    super.initState();
    fetchAlertes();
  }

  Future<void> fetchAlertes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      await http.get(
        Uri.parse('http://192.168.11.243:8000/api/alerts/generate/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      final response = await http.get(
        Uri.parse('http://192.168.11.243:8000/api/alerts/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> nouvellesAlertes = json.decode(response.body);
        setState(() {
          alertes = nouvellesAlertes;
          isLoading = false;
        });

        for (var alerte in nouvellesAlertes) {
          if (alerte['niveau'] == 'critique') {
            await _notificationService.showNotification('Alerte Critique');
            await _emailService.sendAlertEmail(alerte);
          }
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> resolveAlerte(String alerteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.post(
        Uri.parse('http://192.168.11.243:8000/api/alerts/$alerteId/resolve/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await fetchAlertes();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alerte résolue avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la résolution de l\'alerte'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la résolution de l\'alerte'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'permis':
        return Colors.orange;
      case 'assurance':
        return Colors.red;
      case 'controle_technique':
        return Colors.blue;
      case 'entretien':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'permis':
        return Icons.drive_eta;
      case 'assurance':
        return Icons.security;
      case 'controle_technique':
        return Icons.build;
      case 'entretien':
        return Icons.engineering;
      default:
        return Icons.warning;
    }
  }

  String _formatTypeAlerte(String type) {
    switch (type) {
      case 'entretien':
        return 'Entretien';
      case 'assurance':
        return 'Assurance';
      case 'controle_technique':
        return 'Contrôle technique';
      case 'permis':
        return 'Permis';
      default:
        return 'Autre';
    }
  }

  Widget _buildNiveauBadge(String niveau) {
    Color couleur;
    switch (niveau) {
      case 'critique':
        couleur = Colors.red;
        break;
      case 'warning':
        couleur = Colors.orange;
        break;
      default:
        couleur = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur),
      ),
      child: Text(
        niveau.toUpperCase(),
        style: GoogleFonts.poppins(
          color: couleur,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showAlerteDetailDialog(BuildContext context, dynamic alerte) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getTypeIcon(alerte['type_alerte']),
                    color: _getTypeColor(alerte['type_alerte']),
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Détails de l\'alerte',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Type', _formatTypeAlerte(alerte['type_alerte'])),
              if (alerte['vehicle'] != null)
                _buildDetailRow('Véhicule', alerte['vehicle']),
              if (alerte['driver'] != null)
                _buildDetailRow('Conducteur', alerte['driver']),
              _buildDetailRow(
                'Date',
                DateFormat('dd/MM/yyyy')
                    .format(DateTime.parse(alerte['date_alerte'])),
              ),
              _buildDetailRow('Niveau', alerte['niveau']),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                alerte['message'],
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Fermer', style: GoogleFonts.poppins()),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      resolveAlerte(alerte['code'].toString());
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: Text('Résoudre', style: GoogleFonts.poppins()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  Widget _buildAlerteCard(Map<String, dynamic> alerte) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _showAlerteDetailDialog(context, alerte),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getTypeIcon(alerte['type_alerte']),
                    color: _getTypeColor(alerte['type_alerte']),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _formatTypeAlerte(alerte['type_alerte']),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _buildNiveauBadge(alerte['niveau']),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                alerte['message'],
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(alerte['date_alerte']))}',
                    style:
                        GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.green),
                    onPressed: () => resolveAlerte(alerte['code']),
                    tooltip: 'Résoudre',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<dynamic> getFilteredAlertes() {
    return alertes.where((alerte) {
      final matchesSearch =
          alerte['message'].toLowerCase().contains(searchQuery.toLowerCase()) ||
              _formatTypeAlerte(alerte['type_alerte'])
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase());
      final matchesType =
          selectedType == 'Tous' || alerte['type_alerte'] == selectedType;
      return matchesSearch && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FC),
        drawer: isMobile ? const AdminMenu() : null,
        appBar: isMobile
            ? AppBar(
                title: Text(
                  'Alertes',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.white, // <-- texte en blanc
                      fontWeight: FontWeight.w600,
                      fontSize: 20, // tu peux ajuster la taille si besoin
                    ),
                  ),
                ),
                backgroundColor: const Color(0xFF002244),
                iconTheme: const IconThemeData(
                  color: Colors.white, // menu hamburger en blanc
                ),
              )
            : null,
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile) const AdminMenu(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderResponsive(isMobile),
                      const SizedBox(height: 16),
                      _buildSearchAndFiltersResponsive(isMobile),
                      const SizedBox(height: 24),
                      _buildAlertList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderResponsive(bool isMobile) {
    if (isMobile) {
      return Text(
        'Gestion des Alertes',
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF002244),
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Gestion des Alertes',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF002244),
            ),
          ),
          SizedBox(
            width: 250,
            child: SwitchListTile(
              title: Text('Afficher les alertes résolues',
                  style: GoogleFonts.poppins()),
              value: showResolved,
              onChanged: (value) {
                setState(() {
                  showResolved = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSearchAndFiltersResponsive(bool isMobile) {
    final filtersAndSearch = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            SizedBox(
              width: isMobile ? double.infinity : 240,
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  labelText: 'Rechercher une alerte',
                  hintText: 'Type, message...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(
              width: isMobile ? double.infinity : 200,
              child: DropdownButtonFormField<String>(
                value: selectedType,
                onChanged: (value) => setState(() => selectedType = value!),
                decoration: const InputDecoration(
                  labelText: 'Type d\'alerte',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: typesAlertes
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(_formatTypeAlerte(e),
                              style: GoogleFonts.poppins()),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ],
    );

    final testButton = ElevatedButton.icon(
      onPressed: () async {
        await _notificationService.showNotification('Test Notification');
        await _notificationService
            .scheduleNotification('Notification Programmée');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications de test envoyées'),
            backgroundColor: Colors.green,
          ),
        );
      },
      icon: const Icon(Icons.notifications),
      label: Text('Tester les notifications', style: GoogleFonts.poppins()),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          filtersAndSearch,
          const SizedBox(height: 12),
          testButton,
        ],
      );
    } else {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              filtersAndSearch,
              testButton,
            ],
          ),
        ),
      );
    }
  }

  Widget _buildAlertList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredAlertes = getFilteredAlertes();
    if (filteredAlertes.isEmpty) {
      return Center(
        child: Text(
          'Aucune alerte trouvée',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredAlertes.length,
      itemBuilder: (context, index) {
        return _buildAlerteCard(filteredAlertes[index]);
      },
    );
  }
}

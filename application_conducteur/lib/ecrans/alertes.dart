import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AlertesPage extends StatefulWidget {
  const AlertesPage({super.key});

  @override
  State<AlertesPage> createState() => _AlertesPageState();
}

class _AlertesPageState extends State<AlertesPage> {
  bool isMobile = false;
  final Color greenPrimary = const Color(0xFF2F855A);
  final Color greenLight = const Color(0xFF81E6D9);
  final Color greyLight = const Color(0xFFF0F4F8);
  final Color textPrimary = const Color(0xFF1A202C);

  List<dynamic> alertes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAlertes();
  }

  Future<void> _fetchAlertes() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final backendUrl = prefs.getString('backend_url') ?? 'http://localhost:8000';
      if (token == null) throw Exception('Utilisateur non authentifié');
      final url = Uri.parse('$backendUrl/api/alerts/mes_alertes/');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          alertes = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'permis':
        return Icons.badge_outlined;
      case 'assurance':
        return Icons.verified_user_outlined;
      case 'controle_technique':
        return Icons.build_circle_outlined;
      case 'entretien':
        return Icons.build;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  Color _getColorForNiveau(String niveau) {
    switch (niveau) {
      case 'critique':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return greenPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 8,
              shadowColor: greenPrimary.withOpacity(0.13),
              iconTheme: IconThemeData(color: textPrimary),
              title: Text(
                'Alertes',
                style: GoogleFonts.poppins(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                ),
              ),
            )
          : null,
      drawer: isMobile ? const Menu() : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _fetchAlertes,
                  child: alertes.isEmpty
                      ? Center(
                          child: Text(
                            'Aucune alerte pour le moment.',
                            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          itemCount: alertes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final alerte = alertes[index];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: ListTile(
                                leading: Icon(_getIconForType(alerte['type_alerte'] ?? ''), color: _getColorForNiveau(alerte['niveau'] ?? ''), size: 36),
                                title: Text(
                                  alerte['message'] ?? '',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (alerte['vehicle'] != null)
                                      Text('Véhicule : ${alerte['vehicle']}', style: TextStyle(color: Colors.grey[700])),
                                    if (alerte['driver'] != null)
                                      Text('Conducteur : ${alerte['driver']}', style: TextStyle(color: Colors.grey[700])),
                                    Row(
                                      children: [
                                        Chip(
                                          label: Text((alerte['type_alerte'] ?? '').toUpperCase()),
                                          backgroundColor: greenLight.withOpacity(0.2),
                                        ),
                                        const SizedBox(width: 8),
                                        Chip(
                                          label: Text((alerte['niveau'] ?? '').toUpperCase()),
                                          backgroundColor: _getColorForNiveau(alerte['niveau'] ?? '').withOpacity(0.15),
                                          labelStyle: TextStyle(color: _getColorForNiveau(alerte['niveau'] ?? '')),
                                        ),
                                        const SizedBox(width: 8),
                                        if (alerte['date_alerte'] != null)
                                          Text(
                                            (alerte['date_alerte'] as String).substring(0, 10),
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

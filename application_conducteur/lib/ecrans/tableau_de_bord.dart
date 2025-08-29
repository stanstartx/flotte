import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';

class TableauDeBord extends StatelessWidget {
  const TableauDeBord({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FD),
          drawer: isMobile ? const Menu() : null,
          body: Row(
            children: [
              if (!isMobile) const Menu(),
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
                              'Tableau de bord',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A237E),
                              ),
                            ),
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 24,
                              child: Icon(
                                Icons.account_circle,
                                color: Colors.grey[700],
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 24,
                          runSpacing: 24,
                          children: const [
                            PremiumStatCard(
                              icon: Icons.assignment,
                              label: 'Missions en cours',
                              value: '3',
                              gradient: LinearGradient(
                                colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                              ),
                            ),
                            PremiumStatCard(
                              icon: Icons.directions_car,
                              label: 'Véhicule attribué',
                              value: 'Peugeot 208',
                              gradient: LinearGradient(
                                colors: [Color(0xFF66BB6A), Color(0xFF388E3C)],
                              ),
                            ),
                            PremiumStatCard(
                              icon: Icons.warning_amber,
                              label: 'Alertes importantes',
                              value: '1',
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFA726), Color(0xFFF57C00)],
                              ),
                            ),
                            PremiumStatCard(
                              icon: Icons.speed,
                              label: 'Km parcourus',
                              value: '1 540 km',
                              gradient: LinearGradient(
                                colors: [Color(0xFFAB47BC), Color(0xFF8E24AA)],
                              ),
                            ),
                            PremiumStatCard(
                              icon: Icons.check_circle,
                              label: 'Missions terminées',
                              value: '12',
                              gradient: LinearGradient(
                                colors: [Color(0xFF26C6DA), Color(0xFF00ACC1)],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        PremiumSection(
                          title: 'Mission en cours',
                          child: const MissionCard(),
                        ),
                        PremiumSection(
                          title: 'Historique des missions',
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                const Color(0xFFEEEEEE),
                              ),
                              columns: const [
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Destination')),
                                DataColumn(label: Text('Véhicule')),
                                DataColumn(label: Text('Durée')),
                                DataColumn(label: Text('Statut')),
                              ],
                              rows: const [
                                DataRow(
                                  cells: [
                                    DataCell(Text('20/05/2025')),
                                    DataCell(Text('Thiès')),
                                    DataCell(Text('Peugeot 208')),
                                    DataCell(Text('1h 20min')),
                                    DataCell(Text('Terminée')),
                                  ],
                                ),
                                DataRow(
                                  cells: [
                                    DataCell(Text('18/05/2025')),
                                    DataCell(Text('Saint-Louis')),
                                    DataCell(Text('Toyota Yaris')),
                                    DataCell(Text('3h 10min')),
                                    DataCell(Text('Terminée')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // ------------------- Section Documents personnels améliorée -------------------
                        PremiumSection(
                          title: 'Documents personnels',
                          child: const DocumentsPersonnelsCard(),
                        ),
                        // -------------------------------------------------------------------------------
                        PremiumSection(
                          title: 'Notifications',
                          child: Column(
                            children: const [
                              PremiumNotification(
                                icon: Icons.mail_outline,
                                message:
                                    'Votre mission vers Dakar commence dans 2h.',
                              ),
                              PremiumNotification(
                                icon: Icons.warning_amber_outlined,
                                message: 'Votre assurance expire bientôt.',
                              ),
                              PremiumNotification(
                                icon: Icons.celebration,
                                message: '12 missions terminées ce mois-ci !',
                              ),
                            ],
                          ),
                        ),
                        PremiumSection(
                          title: 'Raccourcis utiles',
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3949AB),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {},
                                icon: const Icon(Icons.report_problem),
                                label: const Text('Déclarer une panne'),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00897B),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {},
                                icon: const Icon(Icons.support_agent),
                                label: const Text('Contacter un gestionnaire'),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5E35B1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {},
                                icon: const Icon(Icons.download),
                                label: const Text(
                                  'Télécharger une fiche mission',
                                ),
                              ),
                            ],
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
}

class PremiumStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Gradient gradient;

  const PremiumStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumSection extends StatelessWidget {
  final String title;
  final Widget child;

  const PremiumSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class PremiumNotification extends StatelessWidget {
  final IconData icon;
  final String message;

  const PremiumNotification({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Icon(icon, color: const Color(0xFF3949AB)),
      title: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
    );
  }
}

class MissionCard extends StatelessWidget {
  const MissionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Destination : Dakar', style: GoogleFonts.poppins(fontSize: 14)),
          Text(
            'Véhicule : Toyota Hilux',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          Text(
            'Durée estimée : 3h 30min',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Voir fiche mission'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1A237E),
                  side: const BorderSide(color: Color(0xFF1A237E)),
                ),
                child: const Text('Démarrer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----- Nouvelle classe pour la section Documents Personnels -----

class DocumentsPersonnelsCard extends StatelessWidget {
  const DocumentsPersonnelsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final docs = [
      {
        'icon': Icons.card_membership,
        'title': 'Permis',
        'status': 'Valide jusqu’au 12/12/2026',
        'color': Colors.green,
      },
      {
        'icon': Icons.credit_card,
        'title': 'Carte d’identité',
        'status': 'Valide',
        'color': Colors.green,
      },
      {
        'icon': Icons.verified_user,
        'title': 'Assurance',
        'status': 'Expire le 10/03/2026',
        'color': Colors.orange,
      },
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Documents personnels',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 20),
            ...docs.map((doc) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      doc['icon'] as IconData,
                      color: doc['color'] as Color,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${doc['title']} :',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (doc['color'] as Color).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        doc['status'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: doc['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

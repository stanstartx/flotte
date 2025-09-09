import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:application_conducteur/widgets/menu.dart';

const Color kGreenDark = Color(0xFF14532D);
const Color kGreen = Color(0xFF22C55E);
const Color kBlue = Color(0xFF2563EB);
const Color kOrange = Color(0xFFF59E42);
const Color kRed = Color(0xFFEF4444);
const Color kGreyText = Color(0xFF64748B);
const Color kBlack = Color(0xFF1E293B);

class ParametresPage extends StatefulWidget {
  const ParametresPage({super.key});

  @override
  State<ParametresPage> createState() => _ParametresPageState();
}

class _ParametresPageState extends State<ParametresPage> {
  // --- State ---
  String _nom = 'Jean Kouassi';
  String _email = 'jean.kouassi@mail.com';
  String _tel = '+225 01 23 45 67';
  String _dob = '01/01/1990';
  String _adresse = 'Abidjan, Côte d\'Ivoire';
  String _numPermis = '123456789';
  String _photoUrl = 'https://via.placeholder.com/150';

  // Notifications
  bool _notifMissionAssign = true;
  bool _notifMissionCancelled = true;
  bool _notifReminder = false;
  bool _notifNextService = true;

  // Localisation
  bool _gpsEnabled = true;
  bool _shareLocation = true;

  // Langue & thème
  String _lang = 'Français';
  bool _darkMode = false;

  // Véhicule assigné
  final Map<String, String> _vehicule = const {
    'modele': 'Toyota Hilux',
    'immat': 'AB-1234-ZZ',
    'km': '84 230 km',
    'couleur': 'Blanc',
    'annee': '2022',
    'carburant': 'Diesel',
    'vin': 'JTEB1234567890000',
  };

  // Utils
  bool get isMobile => MediaQuery.of(context).size.width < 700;

  // ---------- Modales ----------
  void _openHeaderDialog({
    required String title,
    required IconData icon,
    required Widget child,
    Color headerColor = kBlue,
    List<Widget>? actions,
    EdgeInsets contentPadding = const EdgeInsets.all(24),
  }) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 40,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: headerColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(padding: contentPadding, child: child),
                if (actions != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions,
                    ),
                  ),
                ],
              ],
            ),
          ),
    );
  }

  void _openEditProfileModal() {
    final nomCtrl = TextEditingController(text: _nom);
    final emailCtrl = TextEditingController(text: _email);
    final telCtrl = TextEditingController(text: _tel);
    final dobCtrl = TextEditingController(text: _dob);
    final adrCtrl = TextEditingController(text: _adresse);
    final permisCtrl = TextEditingController(text: _numPermis);

    _openHeaderDialog(
      title: 'Modifier le profil',
      icon: Icons.edit,
      child: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: () {},
              child: CircleAvatar(
                radius: 48,
                backgroundColor: kGreyText.withOpacity(0.2),
                backgroundImage: NetworkImage(_photoUrl),
                child: const Icon(Icons.camera_alt, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            _EditField(label: 'Nom', controller: nomCtrl),
            _EditField(label: 'Email', controller: emailCtrl),
            _EditField(label: 'Téléphone', controller: telCtrl),
            _EditField(label: 'Date de naissance', controller: dobCtrl),
            _EditField(label: 'Adresse', controller: adrCtrl),
            _EditField(label: 'Numéro de permis', controller: permisCtrl),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _nom = nomCtrl.text;
              _email = emailCtrl.text;
              _tel = telCtrl.text;
              _dob = dobCtrl.text;
              _adresse = adrCtrl.text;
              _numPermis = permisCtrl.text;
            });
            Navigator.pop(context);
          },
          icon: const Icon(Icons.save),
          label: const Text('Enregistrer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kBlue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _openNotificationsModal() {
    bool tempAssign = _notifMissionAssign;
    bool tempCancel = _notifMissionCancelled;
    bool tempReminder = _notifReminder;
    bool tempService = _notifNextService;

    _openHeaderDialog(
      title: 'Notifications',
      icon: Icons.notifications_active,
      child: Column(
        children: [
          _SwitchRow(
            label: 'Nouvelle mission assignée',
            value: tempAssign,
            onChanged: (v) => setState(() => tempAssign = v),
          ),
          _SwitchRow(
            label: 'Mission annulée',
            value: tempCancel,
            onChanged: (v) => setState(() => tempCancel = v),
          ),
          _SwitchRow(
            label: 'Rappel de mission',
            value: tempReminder,
            onChanged: (v) => setState(() => tempReminder = v),
          ),
          _SwitchRow(
            label: 'Prochain entretien véhicule',
            value: tempService,
            onChanged: (v) => setState(() => tempService = v),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Astuce : tu peux désactiver temporairement pendant une réunion.',
              style: GoogleFonts.poppins(fontSize: 12, color: kGreyText),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _notifMissionAssign = tempAssign;
              _notifMissionCancelled = tempCancel;
              _notifReminder = tempReminder;
              _notifNextService = tempService;
            });
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Appliquer'),
        ),
      ],
    );
  }

  void _openVehiculeSheetModal() {
    _openHeaderDialog(
      title: 'Fiche véhicule',
      icon: Icons.directions_car_filled,
      child: Column(
        children: [
          _KeyValueRow('Modèle', _vehicule['modele']!),
          _KeyValueRow('Immatriculation', _vehicule['immat']!),
          _KeyValueRow('Kilométrage', _vehicule['km']!),
          _KeyValueRow('Couleur', _vehicule['couleur']!),
          _KeyValueRow('Année', _vehicule['annee']!),
          _KeyValueRow('Carburant', _vehicule['carburant']!),
          _KeyValueRow('N° de châssis (VIN)', _vehicule['vin']!),
          const SizedBox(height: 12),
          Row(
            children: [
              _ChipStatus(label: 'Assurance', color: kGreen),
              const SizedBox(width: 8),
              _ChipStatus(label: 'Visite tech.', color: kOrange),
              const SizedBox(width: 8),
              _ChipStatus(label: 'Entretiens à jour', color: kGreenDark),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  void _openChangePasswordModal() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    _openHeaderDialog(
      title: 'Modifier le mot de passe',
      icon: Icons.lock_reset,
      child: Column(
        children: [
          _EditField(
            label: 'Ancien mot de passe',
            controller: oldCtrl,
            obscure: true,
          ),
          _EditField(
            label: 'Nouveau mot de passe',
            controller: newCtrl,
            obscure: true,
          ),
          _EditField(
            label: 'Confirmer le mot de passe',
            controller: confirmCtrl,
            obscure: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => _snack('Mot de passe mis à jour.'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Mettre à jour'),
        ),
      ],
    );
  }

  void _openFAQModal() {
    _openHeaderDialog(
      title: 'FAQ',
      icon: Icons.help_outline,
      child: Column(
        children: [
          _FaqTile(
            q: 'Comment recevoir une mission ?',
            a: 'Les missions sont assignées par le gestionnaire et apparaissent automatiquement.',
          ),
          _FaqTile(
            q: 'Puis-je modifier mes informations ?',
            a: 'Oui, depuis la section Profil conducteur → Modifier les informations.',
          ),
          _FaqTile(
            q: 'Comment activer/désactiver les notifications ?',
            a: 'Paramètres → Notifications → Gérer.',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  void _openContactSupportModal() {
    final sujetCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    _openHeaderDialog(
      title: 'Contacter le support',
      icon: Icons.support_agent,
      child: Column(
        children: [
          _EditField(label: 'Sujet', controller: sujetCtrl),
          _TextArea(label: 'Message', controller: msgCtrl),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => _snack('Message envoyé au support.'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Envoyer'),
        ),
      ],
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          isMobile
              ? AppBar(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0,
                iconTheme: const IconThemeData(color: kBlue),
                title: Row(
                  children: [
                    const Icon(Icons.settings, color: kBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Paramètres',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: kBlack,
                      ),
                    ),
                  ],
                ),
              )
              : null,
      drawer: isMobile ? const Menu() : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) const Menu(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile)
                        Text(
                          'Paramètres',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      const SizedBox(height: 30),

                      // PROFIL
                      _SectionCard(
                        title: 'Profil conducteur',
                        icon: Icons.person,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(_photoUrl),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _KeyValueRow('Nom', _nom),
                          _KeyValueRow('Email', _email),
                          _KeyValueRow('Téléphone', _tel),
                          _KeyValueRow('Date de naissance', _dob),
                          _KeyValueRow('Adresse', _adresse),
                          _KeyValueRow('N° de permis', _numPermis),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: _openEditProfileModal,
                              icon: const Icon(Icons.edit),
                              label: const Text('Modifier le profil'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // SÉCURITÉ
                      _SectionCard(
                        title: 'Sécurité',
                        icon: Icons.lock,
                        children: [
                          _KeyValueRow('Mot de passe', '********'),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton(
                              onPressed: _openChangePasswordModal,
                              child: const Text('Modifier le mot de passe'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // NOTIFICATIONS
                      _SectionCard(
                        title: 'Notifications',
                        icon: Icons.notifications,
                        children: [
                          _KeyValueRow(
                            'Paramètres des notifications',
                            'Personnaliser',
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton(
                              onPressed: _openNotificationsModal,
                              child: const Text('Gérer'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // VÉHICULE
                      _SectionCard(
                        title: 'Véhicule assigné',
                        icon: Icons.directions_car,
                        children: [
                          _KeyValueRow('Modèle', _vehicule['modele']!),
                          _KeyValueRow('Immatriculation', _vehicule['immat']!),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton(
                              onPressed: _openVehiculeSheetModal,
                              child: const Text('Voir la fiche'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // SUPPORT
                      _SectionCard(
                        title: 'Support & FAQ',
                        icon: Icons.help_outline,
                        children: [
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _openFAQModal,
                                icon: const Icon(Icons.article_outlined),
                                label: const Text('FAQ'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: _openContactSupportModal,
                                icon: const Icon(Icons.support_agent),
                                label: const Text('Contacter support'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Widgets ----------
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: kBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  const _KeyValueRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label :',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(color: kGreyText)),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  const _EditField({
    required this.label,
    required this.controller,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    );
  }
}

class _TextArea extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _TextArea({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool) onChanged;
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: GoogleFonts.poppins(fontSize: 14)),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ChipStatus extends StatelessWidget {
  final String label;
  final Color color;
  const _ChipStatus({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String q;
  final String a;
  const _FaqTile({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        q,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            a,
            style: GoogleFonts.poppins(fontSize: 13, color: kGreyText),
          ),
        ),
      ],
    );
  }
}

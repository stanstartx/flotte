import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flotte/widgets/menu_admin/admin_menu.dart';

class ParametresPage extends StatefulWidget {
  const ParametresPage({super.key});

  @override
  State<ParametresPage> createState() => _ParametresPageState();
}

class _ParametresPageState extends State<ParametresPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _motDePasseController = TextEditingController();
  final _intervalleEntretienController = TextEditingController();
  final _limiteKmController = TextEditingController();

  bool _isLoading = false;

  // Switches notifications
  bool _notifEntretien = true;
  bool _notifPanne = true;
  bool _notifAssurance = true;
  bool _notifRapports = true;

  // Accordéons ouverts
  List<bool> _openSections = [true, false, false, false, false];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    _emailController.text = prefs.getString('gestionnaire_email') ?? '';
    _notifEntretien = prefs.getBool('notif_entretien') ?? true;
    _notifPanne = prefs.getBool('notif_panne') ?? true;
    _notifAssurance = prefs.getBool('notif_assurance') ?? true;
    _notifRapports = prefs.getBool('notif_rapports') ?? true;

    _intervalleEntretienController.text =
        prefs.getString('intervalle_entretien') ?? '5000';
    _limiteKmController.text = prefs.getString('limite_km') ?? '200000';

    setState(() {});
  }

  Future<void> _savePreferences() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('gestionnaire_email', _emailController.text);
        await prefs.setBool('notif_entretien', _notifEntretien);
        await prefs.setBool('notif_panne', _notifPanne);
        await prefs.setBool('notif_assurance', _notifAssurance);
        await prefs.setBool('notif_rapports', _notifRapports);
        await prefs.setString(
            'intervalle_entretien', _intervalleEntretienController.text);
        await prefs.setString('limite_km', _limiteKmController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres enregistrés avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'enregistrement'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _motDePasseController.dispose();
    _intervalleEntretienController.dispose();
    _limiteKmController.dispose();
    super.dispose();
  }

  Widget _buildCard(
      {required String title, required Widget child, required int index}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionPanelList(
        elevation: 0,
        expansionCallback: (panelIndex, isExpanded) {
          setState(() {
            _openSections[index] = !_openSections[index];
          });
        },
        children: [
          ExpansionPanel(
            canTapOnHeader: true,
            isExpanded: _openSections[index],
            headerBuilder: (context, isExpanded) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
              );
            },
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: isMobile
          ? AppBar(
              title: const Text(
                'Paramètres',
                style: TextStyle(color: Colors.white), // texte blanc
              ),
              backgroundColor: const Color(0xFF002244),
              iconTheme: const IconThemeData(
                color: Colors.white, // icône hamburger blanche
              ),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            )
          : null,
      drawer: isMobile ? AdminMenu() : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!isMobile) AdminMenu(),
            Expanded(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment:
                        MainAxisAlignment.start, // contenu aligné en haut
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paramètres',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF002244),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Notifications
                              _buildCard(
                                title: 'Notifications',
                                index: 0,
                                child: Column(
                                  children: [
                                    SwitchListTile(
                                      title: const Text('Alertes entretien'),
                                      value: _notifEntretien,
                                      onChanged: (v) =>
                                          setState(() => _notifEntretien = v),
                                    ),
                                    SwitchListTile(
                                      title: const Text('Alertes panne'),
                                      value: _notifPanne,
                                      onChanged: (v) =>
                                          setState(() => _notifPanne = v),
                                    ),
                                    SwitchListTile(
                                      title: const Text('Alertes assurance'),
                                      value: _notifAssurance,
                                      onChanged: (v) =>
                                          setState(() => _notifAssurance = v),
                                    ),
                                    SwitchListTile(
                                      title:
                                          const Text('Rapports hebdomadaires'),
                                      value: _notifRapports,
                                      onChanged: (v) =>
                                          setState(() => _notifRapports = v),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _emailController,
                                      decoration: const InputDecoration(
                                        labelText: 'Email de l\'admin',
                                        hintText: 'exemple@email.com',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty)
                                          return 'Veuillez entrer un email';
                                        if (!value.contains('@') ||
                                            !value.contains('.'))
                                          return 'Email invalide';
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Flotte
                              _buildCard(
                                title: 'Paramètres de la flotte',
                                index: 1,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller:
                                          _intervalleEntretienController,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Intervalle d’entretien (km)',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _limiteKmController,
                                      decoration: const InputDecoration(
                                        labelText:
                                            'Kilométrage maximal du véhicule',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Sécurité
                              _buildCard(
                                title: 'Sécurité',
                                index: 2,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _motDePasseController,
                                      decoration: const InputDecoration(
                                        labelText: 'Changer mot de passe',
                                        border: OutlineInputBorder(),
                                      ),
                                      obscureText: true,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Sauvegardes / Export
                              _buildCard(
                                title: 'Sauvegardes & Export',
                                index: 3,
                                child: Column(
                                  children: const [
                                    ListTile(
                                      leading: Icon(Icons.download),
                                      title: Text('Exporter l’historique CSV'),
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.backup),
                                      title: Text('Sauvegarde manuelle'),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Personnalisation
                              _buildCard(
                                title: 'Personnalisation',
                                index: 4,
                                child: Column(
                                  children: const [
                                    ListTile(
                                      leading: Icon(Icons.color_lens),
                                      title: Text(
                                          'Modifier les couleurs et le logo'),
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.language),
                                      title: Text('Langue et fuseau horaire'),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Bouton Enregistrer
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _savePreferences,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : const Text(
                                          'Enregistrer tous les paramètres'),
                                ),
                              ),
                              const SizedBox(height: 24),
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
      ),
    );
  }
}

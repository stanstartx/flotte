import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flotte/widgets/menu_admin/admin_menu.dart';

class UtilisateursPage extends StatefulWidget {
  const UtilisateursPage({super.key});

  @override
  State<UtilisateursPage> createState() => _UtilisateursPageState();
}

class _UtilisateursPageState extends State<UtilisateursPage>
    with SingleTickerProviderStateMixin {
  String searchQuery = '';
  String selectedStatut = 'Tous';
  late TabController _tabController;

  final List<String> statuts = ['Tous', 'Actif', 'Inactif', 'Suspendu'];

  final List<Map<String, String>> conducteurs = [
    {
      'nom': 'Diallo',
      'prenom': 'Fatou',
      'identifiant': 'fdiallo',
      'statut': 'Actif',
      'email': 'fatou.diallo@mail.com',
      'tel': '0700000001',
      'adresse': 'Abidjan',
      'permis': 'CI12345',
      'categorie': 'B',
      'naissance': '01/01/1990',
      'expiration': '01/01/2030'
    },
  ];

  final List<Map<String, String>> administrateurs = [
    {
      'nom': 'Admin',
      'prenom': 'Super',
      'identifiant': 'admin01',
      'statut': 'Actif',
      'email': 'admin@mail.com',
      'tel': '0700000002',
      'adresse': 'Plateau'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  /// ----------- AJOUT / MODIF UTILISATEUR -------------
  void _showUserFormDialog(bool isConducteur,
      {Map<String, String>? user}) async {
    final TextEditingController nomCtrl =
        TextEditingController(text: user?['nom'] ?? '');
    final TextEditingController prenomCtrl =
        TextEditingController(text: user?['prenom'] ?? '');
    final TextEditingController emailCtrl =
        TextEditingController(text: user?['email'] ?? '');
    final TextEditingController telCtrl =
        TextEditingController(text: user?['tel'] ?? '');
    final TextEditingController adresseCtrl =
        TextEditingController(text: user?['adresse'] ?? '');
    final TextEditingController permisCtrl =
        TextEditingController(text: user?['permis'] ?? '');
    final TextEditingController categorieCtrl =
        TextEditingController(text: user?['categorie'] ?? '');
    final TextEditingController naissanceCtrl =
        TextEditingController(text: user?['naissance'] ?? '');
    final TextEditingController expirationCtrl =
        TextEditingController(text: user?['expiration'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 80, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user == null
                        ? (isConducteur
                            ? 'Ajouter Conducteur'
                            : 'Ajouter Administrateur')
                        : (isConducteur
                            ? 'Modifier Conducteur'
                            : 'Modifier Administrateur'),
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nomCtrl,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                  TextField(
                    controller: prenomCtrl,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                  ),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: telCtrl,
                    decoration: const InputDecoration(labelText: 'Téléphone'),
                  ),
                  TextField(
                    controller: adresseCtrl,
                    decoration: const InputDecoration(labelText: 'Adresse'),
                  ),
                  if (isConducteur) ...[
                    TextField(
                      controller: permisCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Numéro de permis'),
                    ),
                    TextField(
                      controller: categorieCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Catégorie de voiture'),
                    ),
                    TextField(
                      controller: naissanceCtrl,
                      readOnly: true,
                      decoration:
                          const InputDecoration(labelText: 'Date de naissance'),
                      onTap: () async {
                        DateTime? date = await showDatePicker(
                          context: context,
                          initialDate: DateTime(1990),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          naissanceCtrl.text =
                              DateFormat('dd/MM/yyyy').format(date);
                        }
                      },
                    ),
                    TextField(
                      controller: expirationCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                          labelText: 'Date expiration permis'),
                      onTap: () async {
                        DateTime? date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          expirationCtrl.text =
                              DateFormat('dd/MM/yyyy').format(date);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Sauvegarde / Update
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF002244),
                        foregroundColor: Colors.white),
                    child: Text(user == null ? 'Ajouter' : 'Mettre à jour'),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ----------- VOIR UTILISATEUR -------------
  void _showUserDetailDialog(bool isConducteur, Map<String, String> user) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 80, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      isConducteur ? "Détails Conducteur" : "Détails Admin",
                      style: GoogleFonts.poppins(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text("Nom : ${user['nom']}"),
                  Text("Prénom : ${user['prenom']}"),
                  Text("Email : ${user['email']}"),
                  Text("Téléphone : ${user['tel']}"),
                  Text("Adresse : ${user['adresse']}"),
                  if (isConducteur) ...[
                    Text("Permis : ${user['permis']}"),
                    Text("Catégorie : ${user['categorie']}"),
                    Text("Naissance : ${user['naissance']}"),
                    Text("Expiration permis : ${user['expiration']}"),
                  ],
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Télécharger fiche PDF
                      },
                      icon: const Icon(Icons.download),
                      label: const Text("Télécharger"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF002244),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// ----------- TABLEAU UTILISATEURS -------------
  Widget _buildUserTable(bool isConducteur, List<Map<String, String>> users) {
    final filteredUsers = users.where((user) {
      final matchesSearch = user['nom']!
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          user['prenom']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          user['identifiant']!
              .toLowerCase()
              .contains(searchQuery.toLowerCase());
      final matchesStatus =
          selectedStatut == 'Tous' || user['statut'] == selectedStatut;
      return matchesSearch && matchesStatus;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: isConducteur
              ? const [
                  DataColumn(label: Text('Nom / Prénom')),
                  DataColumn(label: Text('Identifiant')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Téléphone')),
                  DataColumn(label: Text('Actions')),
                ]
              : const [
                  DataColumn(label: Text('Nom / Prénom')),
                  DataColumn(label: Text('Identifiant')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Actions')),
                ],
          rows: filteredUsers.map((user) {
            return DataRow(
              cells: [
                DataCell(Text('${user['nom']} / ${user['prenom']}')),
                DataCell(Text(user['identifiant']!)),
                DataCell(Text(user['statut']!)),
                DataCell(Text(isConducteur ? user['tel']! : user['email']!)),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye,
                            color: Colors.blue),
                        tooltip: "Voir",
                        onPressed: () =>
                            _showUserDetailDialog(isConducteur, user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: "Modifier",
                        onPressed: () =>
                            _showUserFormDialog(isConducteur, user: user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: "Supprimer",
                        onPressed: () {
                          // TODO: supprimer
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// ----------- UI PRINCIPALE -------------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 700;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FC),
          drawer: isMobile ? const AdminMenu() : null,
          appBar: isMobile
              ? AppBar(
                  title: Text(
                    'Utilisateurs',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
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
                          'Gestion des Utilisateurs',
                          style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF002244)),
                        ),
                      const SizedBox(height: 16),

                      /// Filtres
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
                                  onChanged: (value) =>
                                      setState(() => searchQuery = value),
                                  decoration: const InputDecoration(
                                    labelText: 'Rechercher un utilisateur',
                                    hintText: 'Nom, prénom, identifiant...',
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
                                  onChanged: (value) =>
                                      setState(() => selectedStatut = value!),
                                  decoration: const InputDecoration(
                                    labelText: 'Statut',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: statuts
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      /// Bouton ajouter
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final isConducteur =
                                _tabController.index == 0; // 0 = Conducteur
                            _showUserFormDialog(isConducteur);
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: Text(
                            _tabController.index == 0
                                ? "Ajouter Conducteur"
                                : "Ajouter Administrateur",
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF002244),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// Onglets
                      TabBar(
                        controller: _tabController,
                        labelColor: Colors.blue,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Colors.blue,
                        tabs: const [
                          Tab(text: 'Conducteurs'),
                          Tab(text: 'Administrateurs'),
                        ],
                        onTap: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      /// Contenu des onglets
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildUserTable(true, conducteurs),
                            _buildUserTable(false, administrateurs),
                          ],
                        ),
                      )
                    ],
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

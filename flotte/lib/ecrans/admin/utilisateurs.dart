import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flotte/widgets/menu_admin/admin_menu.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<dynamic> conducteurs = [];
  List<dynamic> administrateurs = [];
  bool isLoading = true;
  String? errorMessage;

  final List<String> statuts = ['Tous', 'Actif', 'Inactif', 'Suspendu'];
  final List<String> categoriesPermis = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
  final List<String> roles = ['admin', 'gestionnaire'];
  final List<String> statutsConducteur = ['actif', 'inactif', 'en_conge'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchUsers();
  }

  Future<void> fetchUsers() async {
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

      // Récupérer les conducteurs
      final driversResponse = await http.get(
        Uri.parse('http://192.168.11.243:8000/api/drivers/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (driversResponse.statusCode == 200) {
        final data = json.decode(driversResponse.body);
        conducteurs = data is List ? data : (data['results'] ?? []);
      }

      // Récupérer les administrateurs et gestionnaires
      final usersResponse = await http.get(
        Uri.parse('http://192.168.11.243:8000/api/userprofiles/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (usersResponse.statusCode == 200) {
        final data = json.decode(usersResponse.body);
        final allUsers = data is List ? data : (data['results'] ?? []);
        administrateurs = allUsers.where((user) => 
          user['role'] == 'admin' || user['role'] == 'gestionnaire'
        ).toList();
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de connexion: $e';
        isLoading = false;
      });
      print("Erreur récupération utilisateurs: $e");
    }
  }

  Future<void> createUser(Map<String, dynamic> userData, bool isConducteur) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      // Créer l'utilisateur
      final userResponse = await http.post(
        Uri.parse('http://192.168.11.243:8000/api/auth/register/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': userData['username'],
          'password': userData['password'],
          'email': userData['email'],
          'first_name': userData['first_name'],
          'last_name': userData['last_name'],
          'role': isConducteur ? 'conducteur' : userData['role'],
        }),
      );

      if (userResponse.statusCode == 201) {
        final Map<String, dynamic> created = json.decode(userResponse.body) as Map<String, dynamic>;
        final int profileId = created['profile_id'] as int;

        // Mettre à jour le UserProfile (telephone/adresse/role)
        await http.put(
          Uri.parse('http://192.168.11.243:8000/api/userprofiles/$profileId/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'telephone': userData['telephone'] ?? '',
            'adresse': userData['adresse'] ?? '',
            'role': isConducteur ? 'conducteur' : (userData['role'] ?? 'gestionnaire'),
          }),
        );

        if (isConducteur) {
          // Créer le profil conducteur en liant le profile existant
          final String? photoPath = (userData['photo_path'] as String?)?.trim();
          final List<int>? photoBytes = (userData['photo_bytes'] as List<int>?);
          final String fileName = (userData['photo_filename'] as String?) ?? 'photo.jpg';
          final String? dateNaissance = (userData['date_naissance'] as String?)?.trim();
          final String? dateExpiration = (userData['date_expiration_permis'] as String?)?.trim();

          if ((photoPath != null && photoPath.isNotEmpty) || (photoBytes != null && photoBytes.isNotEmpty)) {
            final uri = Uri.parse('http://192.168.11.243:8000/api/drivers/');
            final request = http.MultipartRequest('POST', uri);
            request.headers['Authorization'] = 'Bearer $token';
            request.fields['user_profile_id'] = profileId.toString();
            request.fields['numero_permis'] = (userData['numero_permis'] ?? '').toString();
            request.fields['permis'] = (userData['categorie_permis'] ?? 'B').toString();
            if (dateNaissance != null && dateNaissance.isNotEmpty) {
              request.fields['date_naissance'] = dateNaissance.split('T').first;
            }
            if (dateExpiration != null && dateExpiration.isNotEmpty) {
              request.fields['date_expiration_permis'] = dateExpiration.split('T').first;
            }
            request.fields['statut'] = (userData['statut'] ?? 'actif').toString();

            try {
              if (photoBytes != null && photoBytes.isNotEmpty) {
                request.files.add(http.MultipartFile.fromBytes('photo', photoBytes, filename: fileName));
              }
            } catch (e) {}

            final streamed = await request.send();
            final resp = await http.Response.fromStream(streamed);
            if (resp.statusCode == 201 || resp.statusCode == 200) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conducteur créé avec succès')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur création conducteur: ${resp.statusCode}')),
              );
            }
          } else {
            final driverData = {
              'user_profile_id': profileId,
              'numero_permis': userData['numero_permis'],
              'permis': userData['categorie_permis'],
              'date_naissance': dateNaissance != null && dateNaissance.isNotEmpty ? dateNaissance.split('T').first : null,
              'date_expiration_permis': dateExpiration != null && dateExpiration.isNotEmpty ? dateExpiration.split('T').first : null,
              'statut': userData['statut'] ?? 'actif',
            };

            final driverResponse = await http.post(
              Uri.parse('http://192.168.11.243:8000/api/drivers/'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: json.encode(driverData),
            );

            if (driverResponse.statusCode == 201) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conducteur créé avec succès')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Erreur lors de la création du profil conducteur')),
              );
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Administrateur créé avec succès')),
          );
        }
        fetchUsers();
      } else {
        try {
          final Map<String, dynamic> error = json.decode(userResponse.body) as Map<String, dynamic>;
          final String message = (error['error'] ?? error['detail'] ?? 'Erreur inconnue').toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $message')),
          );
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur: requête invalide')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> userData, bool isConducteur) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      if (isConducteur) {
        // Mettre à jour le conducteur
        final driverResponse = await http.put(
          Uri.parse('http://192.168.11.243:8000/api/drivers/$id/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'numero_permis': userData['numero_permis'],
            'permis': userData['categorie_permis'],
            'date_naissance': userData['date_naissance'],
            'date_expiration_permis': userData['date_expiration_permis'],
            'statut': userData['statut'],
          }),
        );

        if (driverResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Conducteur modifié avec succès')),
          );
          fetchUsers();
        }
      } else {
        // Mettre à jour le profil utilisateur
        final profileResponse = await http.put(
          Uri.parse('http://192.168.11.243:8000/api/userprofiles/$id/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'telephone': userData['telephone'],
            'adresse': userData['adresse'],
            'role': userData['role'],
          }),
        );

        if (profileResponse.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utilisateur modifié avec succès')),
          );
          fetchUsers();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> deleteUser(int id, bool isConducteur) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return;

      final response = await http.delete(
        Uri.parse(isConducteur 
          ? 'http://192.168.11.243:8000/api/drivers/$id/'
          : 'http://192.168.11.243:8000/api/userprofiles/$id/'
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isConducteur ? 'Conducteur' : 'Utilisateur'} supprimé avec succès')),
        );
        fetchUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  List<dynamic> get filteredConducteurs {
    return conducteurs.where((conducteur) {
      final matchesSearch = 
        conducteur['user_profile']?['user']?['username']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
        conducteur['user_profile']?['user']?['email']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
        conducteur['numero_permis']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true;
      
      final matchesStatut = selectedStatut == 'Tous' || 
                           conducteur['statut']?.toString().toLowerCase() == selectedStatut.toLowerCase();
      
      return matchesSearch && matchesStatut;
    }).toList();
  }

  List<dynamic> get filteredAdministrateurs {
    return administrateurs.where((admin) {
      final matchesSearch = 
        admin['user']?['username']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
        admin['user']?['email']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true;
      
      final matchesStatut = selectedStatut == 'Tous' || 
                           admin['role']?.toString().toLowerCase() == selectedStatut.toLowerCase();
      
      return matchesSearch && matchesStatut;
    }).toList();
  }

  /// ----------- AJOUT / MODIF UTILISATEUR -------------
  void _showUserFormDialog(bool isConducteur,
      {Map<String, dynamic>? user}) async {
    final TextEditingController usernameCtrl =
        TextEditingController(text: user?['user_profile']?['user']?['username'] ?? user?['user']?['username'] ?? '');
    final TextEditingController emailCtrl =
        TextEditingController(text: user?['user_profile']?['user']?['email'] ?? user?['user']?['email'] ?? '');
    final TextEditingController telephoneCtrl =
        TextEditingController(text: user?['user_profile']?['telephone'] ?? user?['telephone'] ?? '');
    final TextEditingController adresseCtrl =
        TextEditingController(text: user?['user_profile']?['adresse'] ?? user?['adresse'] ?? '');
    final TextEditingController passwordCtrl = TextEditingController();
    final TextEditingController photoCtrl = TextEditingController();
    
    // Champs spécifiques aux conducteurs
    final TextEditingController permisCtrl =
        TextEditingController(text: user?['numero_permis'] ?? '');
    String categoriePermis = user?['permis'] ?? 'B';
    String statut = user?['statut'] ?? 'actif';
    String role = user?['user_profile']?['role'] ?? user?['role'] ?? 'conducteur';
    
    // Dates
    DateTime? dateNaissance = user?['date_naissance'] != null 
        ? DateTime.tryParse(user!['date_naissance']) 
        : null;
    DateTime? dateExpiration = user?['date_expiration_permis'] != null 
        ? DateTime.tryParse(user!['date_expiration_permis']) 
        : null;
    List<int>? selectedPhotoBytes; // Octets (web)
    String? selectedPhotoFilename; // Nom de fichier pour l'UI et l'upload

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
            constraints: const BoxConstraints(maxWidth: 500),
            child: StatefulBuilder(
              builder: (context, setStateDialog) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  Text(
                    user == null
                        ? (isConducteur
                            ? 'Ajouter Conducteur'
                            : 'Ajouter Utilisateur')
                        : (isConducteur
                            ? 'Modifier Conducteur'
                            : 'Modifier Utilisateur'),
                    style: GoogleFonts.poppins(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Informations de base
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: usernameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nom d\'utilisateur',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (user == null) // Mot de passe seulement pour les nouveaux utilisateurs
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: passwordCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Mot de passe',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  
                  // Informations de contact
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: telephoneCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: adresseCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Adresse',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Rôle (pour les non-conducteurs)
                  if (!isConducteur)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: role,
                            decoration: const InputDecoration(
                              labelText: 'Rôle',
                              border: OutlineInputBorder(),
                            ),
                            items: roles.map((r) {
                              return DropdownMenuItem<String>(
                                value: r,
                                child: Text(r == 'admin' ? 'Administrateur' : 'Gestionnaire'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              role = value!;
                            },
                          ),
                        ),
                      ],
                    ),
                  
                  // Champs spécifiques aux conducteurs
                  if (isConducteur) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: permisCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Numéro de permis',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: categoriePermis,
                            decoration: const InputDecoration(
                              labelText: 'Catégorie permis',
                              border: OutlineInputBorder(),
                            ),
                            items: categoriesPermis.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat,
                                child: Text(cat),
                              );
                            }).toList(),
                            onChanged: (value) {
                              categoriePermis = value!;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: statut,
                            decoration: const InputDecoration(
                              labelText: 'Statut',
                              border: OutlineInputBorder(),
                            ),
                            items: statutsConducteur.map((s) {
                              return DropdownMenuItem<String>(
                                value: s,
                                child: Text(s == 'actif' ? 'Actif' : s == 'inactif' ? 'Inactif' : 'En congé'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              statut = value!;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Dates pour les conducteurs
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Date de naissance'),
                            subtitle: Text(dateNaissance?.toString().split(' ')[0] ?? 'Non définie'),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: dateNaissance ?? DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setStateDialog(() {
                                  dateNaissance = date;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ListTile(
                            title: const Text('Expiration permis'),
                            subtitle: Text(dateExpiration?.toString().split(' ')[0] ?? 'Non définie'),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: dateExpiration ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 3650)),
                              );
                              if (date != null) {
                                setStateDialog(() {
                                  dateExpiration = date;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Choisir une photo depuis l'appareil
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: photoCtrl,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Photo (optionnel)',
                              hintText: 'Aucune photo sélectionnée',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              allowMultiple: false,
                              withData: true,
                            );
                            if (result != null && result.files.isNotEmpty) {
                              final file = result.files.single;
                              if (file.bytes != null) {
                                setStateDialog(() {
                                  selectedPhotoBytes = file.bytes;
                                  selectedPhotoFilename = file.name;
                                  photoCtrl.text = file.name;
                                });
                              }
                            }
                          },
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Choisir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF002244),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (user == null) {
                            if (usernameCtrl.text.trim().isEmpty ||
                                passwordCtrl.text.trim().isEmpty ||
                                emailCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Veuillez remplir Nom d\'utilisateur, Email et Mot de passe')),
                              );
                              return;
                            }
                            // Création
                            final Map<String, dynamic> userData = {
                              'username': usernameCtrl.text,
                              'password': passwordCtrl.text,
                              'email': emailCtrl.text,
                              'first_name': usernameCtrl.text.split(' ').first,
                              'last_name': usernameCtrl.text.split(' ').length > 1 
                                  ? usernameCtrl.text.split(' ').skip(1).join(' ') 
                                  : '',
                              'role': role,
                              'telephone': telephoneCtrl.text,
                              'adresse': adresseCtrl.text,
                            };
                            
                            if (isConducteur) {
                              userData.addAll({
                                'numero_permis': permisCtrl.text,
                                'categorie_permis': categoriePermis,
                                'date_naissance': dateNaissance?.toIso8601String() ?? '',
                                'date_expiration_permis': dateExpiration?.toIso8601String() ?? '',
                                'statut': statut,
                                'telephone': telephoneCtrl.text,
                                'adresse': adresseCtrl.text,
                                'photo_bytes': selectedPhotoBytes,
                                'photo_filename': selectedPhotoFilename ?? 'photo.jpg',
                              });
                            }
                            
                            await createUser(userData, isConducteur);
                          } else {
                            // Modification
                            final userData = {
                              'telephone': telephoneCtrl.text,
                              'adresse': adresseCtrl.text,
                              'role': role,
                            };
                            
                            if (isConducteur) {
                              userData.addAll({
                                'numero_permis': permisCtrl.text,
                                'categorie_permis': categoriePermis,
                                'date_naissance': dateNaissance?.toIso8601String() ?? '',
                                'date_expiration_permis': dateExpiration?.toIso8601String() ?? '',
                                'statut': statut,
                              });
                            }
                            
                            await updateUser(user['id'], userData, isConducteur);
                          }
                          
                          Navigator.pop(context);
                        },
                        child: Text(user == null ? 'Ajouter' : 'Modifier'),
                      ),
                    ],
                  ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// ----------- VOIR UTILISATEUR -------------
  void _showUserDetailDialog(bool isConducteur, Map<String, dynamic> user) {
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
                  Text("Nom : ${isConducteur ? (user['user_profile']?['user']?['first_name'] ?? '') : (user['user']?['first_name'] ?? '')}"),
                  Text("Prénom : ${isConducteur ? (user['user_profile']?['user']?['last_name'] ?? '') : (user['user']?['last_name'] ?? '')}"),
                  Text("Email : ${isConducteur ? (user['user_profile']?['user']?['email'] ?? '') : (user['user']?['email'] ?? '')}"),
                  Text("Téléphone : ${isConducteur ? (user['user_profile']?['telephone'] ?? '') : 'Non défini'}"),
                  Text("Adresse : ${isConducteur ? (user['user_profile']?['adresse'] ?? '') : 'Non défini'}"),
                  if (isConducteur) ...[
                    Text("Numéro de permis : ${user['numero_permis'] ?? ''}"),
                    Text("Catégorie permis : ${user['permis'] ?? ''}"),
                    if (user['date_naissance'] != null)
                      Text("Date de naissance : ${DateFormat('dd/MM/yyyy').format(DateTime.parse(user['date_naissance']))}"),
                    if (user['date_expiration_permis'] != null)
                      Text("Expiration permis : ${DateFormat('dd/MM/yyyy').format(DateTime.parse(user['date_expiration_permis']))}"),
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
  Widget _buildUserTable(bool isConducteur, List<dynamic> users) {
    final filteredUsers = users.where((user) {
      final matchesSearch = 
        (user['user_profile']?['user']?['username'] ?? user['user']?['username'] ?? '')
            .toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
        (user['user_profile']?['user']?['email'] ?? user['user']?['email'] ?? '')
            .toString().toLowerCase().contains(searchQuery.toLowerCase());
      
      final matchesStatus = selectedStatut == 'Tous' || 
                           (isConducteur 
                             ? (user['statut'] ?? '').toString().toLowerCase() == selectedStatut.toLowerCase()
                             : (user['role'] ?? '').toString().toLowerCase() == selectedStatut.toLowerCase());
      
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
                DataCell(Text(isConducteur 
                  ? '${user['user_profile']?['user']?['first_name'] ?? ''} ${user['user_profile']?['user']?['last_name'] ?? ''}'
                  : '${user['user']?['first_name'] ?? ''} ${user['user']?['last_name'] ?? ''}')),
                DataCell(Text(isConducteur 
                  ? (user['user_profile']?['user']?['username'] ?? '')
                  : (user['user']?['username'] ?? ''))),
                DataCell(Text(isConducteur 
                  ? (user['statut'] ?? '')
                  : (user['role'] ?? ''))),
                DataCell(Text(isConducteur 
                  ? (user['user_profile']?['telephone'] ?? '')
                  : (user['user']?['email'] ?? ''))),
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
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirmer la suppression'),
                              content: Text('Êtes-vous sûr de vouloir supprimer cet utilisateur ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    deleteUser(user['id'], isConducteur);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
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

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

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      // Récupérer les conducteurs
      final driversResponse = await http.get(
        Uri.parse('http://192.168.11.243:8000/api/drivers/'),
        headers: headers,
      );

      if (driversResponse.statusCode == 200) {
        final data = json.decode(driversResponse.body);
        conducteurs = data is List ? data : (data['results'] ?? []);
      }

      // Récupérer les administrateurs et gestionnaires
      final usersResponse = await http.get(
        Uri.parse('http://192.168.11.243:8000/api/userprofiles/'),
        headers: headers,
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

      // CORRECTION: Mettre à jour le UserProfile avec les en-têtes corrects
      final profileUpdateResponse = await http.put(
        Uri.parse('http://192.168.11.243:8000/api/userprofiles/$profileId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json', // IMPORTANT: Spécifier le Content-Type
        },
        body: json.encode({
          'telephone': userData['telephone'] ?? '',
          'adresse': userData['adresse'] ?? '',
          'role': isConducteur ? 'conducteur' : (userData['role'] ?? 'gestionnaire'),
        }),
      );

      // Vérifier si la mise à jour du profil a réussi
      if (profileUpdateResponse.statusCode != 200) {
        print('Erreur mise à jour profil: ${profileUpdateResponse.statusCode} - ${profileUpdateResponse.body}');
      }

      if (isConducteur) {
        // CORRECTION: Préparer les données du conducteur avec validation
        final String numeroPermis = (userData['numero_permis'] as String?)?.trim() ?? '';
        if (numeroPermis.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Le numéro de permis est requis')),
          );
          return;
        }

        final String? photoPath = (userData['photo_path'] as String?)?.trim();
        final List<int>? photoBytes = (userData['photo_bytes'] as List<int>?);
        final String fileName = (userData['photo_filename'] as String?) ?? 'photo.jpg';
        final String? dateNaissance = (userData['date_naissance'] as String?)?.trim();
        final String? dateExpiration = (userData['date_expiration_permis'] as String?)?.trim();

        // CORRECTION: Créer le conducteur avec ou sans photo
        if ((photoPath != null && photoPath.isNotEmpty) || (photoBytes != null && photoBytes.isNotEmpty)) {
          // Avec photo - utiliser multipart
          final uri = Uri.parse('http://192.168.11.243:8000/api/drivers/');
          final request = http.MultipartRequest('POST', uri);
          request.headers['Authorization'] = 'Bearer $token';
          // Ne pas définir Content-Type pour multipart, laissons http le faire automatiquement
          
          // CORRECTION: Champs requis
          request.fields['user_profile_id'] = profileId.toString();
          request.fields['numero_permis'] = numeroPermis;
          request.fields['permis'] = (userData['categorie_permis'] ?? 'B').toString();
          
          // Champs optionnels
          if (dateNaissance != null && dateNaissance.isNotEmpty) {
            try {
              final date = DateTime.parse(dateNaissance);
              request.fields['date_naissance'] = date.toIso8601String().split('T').first;
            } catch (e) {
              print('Erreur parsing date naissance: $e');
            }
          }
          
          if (dateExpiration != null && dateExpiration.isNotEmpty) {
            try {
              final date = DateTime.parse(dateExpiration);
              request.fields['date_expiration_permis'] = date.toIso8601String().split('T').first;
            } catch (e) {
              print('Erreur parsing date expiration: $e');
            }
          }
          
          request.fields['statut'] = (userData['statut'] ?? 'actif').toString();
          request.fields['notes'] = (userData['notes'] ?? '').toString();

          // Ajouter la photo
          try {
            if (photoBytes != null && photoBytes.isNotEmpty) {
              request.files.add(http.MultipartFile.fromBytes('photo', photoBytes, filename: fileName));
            }
          } catch (e) {
            print('Erreur ajout photo: $e');
          }

          final streamed = await request.send();
          final resp = await http.Response.fromStream(streamed);
          
          if (resp.statusCode == 201 || resp.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Conducteur créé avec succès')),
            );
          } else {
            print('Erreur création conducteur multipart: ${resp.statusCode} - ${resp.body}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur création conducteur: ${resp.statusCode}')),
            );
          }
        } else {
          // CORRECTION: Sans photo - utiliser JSON avec validation
          final Map<String, dynamic> driverData = {
            'user_profile_id': profileId,
            'numero_permis': numeroPermis,
            'permis': userData['categorie_permis'] ?? 'B',
            'statut': userData['statut'] ?? 'actif',
            'notes': userData['notes'] ?? '',
          };

          // Ajouter les dates seulement si elles sont valides
          if (dateNaissance != null && dateNaissance.isNotEmpty) {
            try {
              final date = DateTime.parse(dateNaissance);
              driverData['date_naissance'] = date.toIso8601String().split('T').first;
            } catch (e) {
              print('Erreur parsing date naissance: $e');
            }
          }
          
          if (dateExpiration != null && dateExpiration.isNotEmpty) {
            try {
              final date = DateTime.parse(dateExpiration);
              driverData['date_expiration_permis'] = date.toIso8601String().split('T').first;
            } catch (e) {
              print('Erreur parsing date expiration: $e');
            }
          }

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
            print('Erreur création conducteur JSON: ${driverResponse.statusCode} - ${driverResponse.body}');
            
            // CORRECTION: Affichage des erreurs spécifiques
            try {
              final errorData = json.decode(driverResponse.body);
              String errorMsg = 'Erreur lors de la création du conducteur';
              
              if (errorData is Map<String, dynamic>) {
                if (errorData.containsKey('numero_permis')) {
                  errorMsg = 'Numéro de permis: ${errorData['numero_permis'][0]}';
                } else if (errorData.containsKey('user_profile_id')) {
                  errorMsg = 'Profil utilisateur: ${errorData['user_profile_id'][0]}';
                } else if (errorData.containsKey('error')) {
                  errorMsg = errorData['error'].toString();
                }
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(errorMsg)),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Erreur lors de la création du conducteur')),
              );
            }
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Administrateur créé avec succès')),
        );
      }
      
      // Actualiser la liste
      fetchUsers();
    } else {
      // CORRECTION: Gestion des erreurs de création d'utilisateur
      print('Erreur création utilisateur: ${userResponse.statusCode} - ${userResponse.body}');
      
      try {
        final Map<String, dynamic> error = json.decode(userResponse.body) as Map<String, dynamic>;
        String message = 'Erreur inconnue';
        
        if (error.containsKey('username')) {
          message = 'Nom d\'utilisateur: ${error['username'][0]}';
        } else if (error.containsKey('email')) {
          message = 'Email: ${error['email'][0]}';
        } else if (error.containsKey('error')) {
          message = error['error'].toString();
        } else if (error.containsKey('detail')) {
          message = error['detail'].toString();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $message')),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${userResponse.statusCode}')),
        );
      }
    }
  } catch (e) {
    print('Exception lors de la création: $e');
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
    final String photoUrl = user['user_profile']?['photo'] != null && user['user_profile']['photo'].isNotEmpty
        ? (user['user_profile']['photo'].startsWith('http') ? user['user_profile']['photo'] : 'http://192.168.11.243:8000${user['user_profile']['photo']}')
        : '';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
            child: Stack(
              children: [
                // Fond avec photo (si disponible) et overlay pour lisibilité
                if (photoUrl.isNotEmpty)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: NetworkImage(photoUrl),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.4),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Contenu principal
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Text(
                          isConducteur ? "Détails du Conducteur" : "Détails de l'Admin",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: photoUrl.isNotEmpty ? Colors.white : const Color(0xFF002244),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (photoUrl.isEmpty)
                        Center(
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[300],
                            child: const Icon(Icons.person, size: 60, color: Colors.white),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildInfoRow("Nom", isConducteur ? (user['user_profile']?['user']?['first_name'] ?? '') : (user['user']?['first_name'] ?? ''), photoUrl.isNotEmpty),
                      _buildInfoRow("Prénom", isConducteur ? (user['user_profile']?['user']?['last_name'] ?? '') : (user['user']?['last_name'] ?? ''), photoUrl.isNotEmpty),
                      _buildInfoRow("Email", isConducteur ? (user['user_profile']?['user']?['email'] ?? '') : (user['user']?['email'] ?? ''), photoUrl.isNotEmpty),
                      _buildInfoRow("Téléphone", isConducteur ? (user['user_profile']?['telephone'] ?? 'Non défini') : 'Non défini', photoUrl.isNotEmpty),
                      _buildInfoRow("Adresse", isConducteur ? (user['user_profile']?['adresse'] ?? 'Non défini') : 'Non défini', photoUrl.isNotEmpty),
                      if (isConducteur) ...[
                        _buildInfoRow("Numéro de permis", user['numero_permis'] ?? 'Non défini', photoUrl.isNotEmpty),
                        _buildInfoRow("Catégorie permis", user['permis'] ?? 'Non défini', photoUrl.isNotEmpty),
                        if (user['date_naissance'] != null)
                          _buildInfoRow("Date de naissance", DateFormat('dd/MM/yyyy').format(DateTime.parse(user['date_naissance'])), photoUrl.isNotEmpty),
                        if (user['date_expiration_permis'] != null)
                          _buildInfoRow("Expiration permis", DateFormat('dd/MM/yyyy').format(DateTime.parse(user['date_expiration_permis'])), photoUrl.isNotEmpty),
                        _buildInfoRow("Statut", user['statut'] ?? 'Non défini', photoUrl.isNotEmpty),
                      ],
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Télécharger fiche PDF
                          },
                          icon: const Icon(Icons.download),
                          label: const Text("Télécharger PDF"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF002244),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, bool hasBackground) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label :",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: hasBackground ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: hasBackground ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// ----------- TABLEAU UTILISATEURS -------------
  Widget _buildUserTable(bool isConducteur, List<dynamic> users) {
    final filteredUsers = isConducteur ? filteredConducteurs : filteredAdministrateurs;

    if (!isConducteur) {
      // Pour administrateurs, garder le DataTable
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Nom / Prénom')),
              DataColumn(label: Text('Identifiant')),
              DataColumn(label: Text('Statut')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Actions')),
            ],
            rows: filteredUsers.map((user) {
              return DataRow(
                cells: [
                  DataCell(Text('${user['user']?['first_name'] ?? ''} ${user['user']?['last_name'] ?? ''}')),
                  DataCell(Text(user['user']?['username'] ?? '')),
                  DataCell(Text(user['role'] ?? '')),
                  DataCell(Text(user['user']?['email'] ?? '')),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                          tooltip: "Voir",
                          onPressed: () => _showUserDetailDialog(false, user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          tooltip: "Modifier",
                          onPressed: () => _showUserFormDialog(false, user: user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: "Supprimer",
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirmer la suppression'),
                                content: const Text('Êtes-vous sûr de vouloir supprimer cet utilisateur ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      deleteUser(user['id'], false);
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
    } else {
      // Pour conducteurs, cartes carrées 3 par ligne avec photo en fond
      return GridView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          final String name = '${user['user_profile']?['user']?['first_name'] ?? ''} ${user['user_profile']?['user']?['last_name'] ?? ''}';
          final String statut = user['statut'] ?? 'inconnu';
          final String telephone = user['user_profile']?['telephone'] ?? 'Non défini';
          final String numeroPermis = user['numero_permis'] ?? 'Non défini';
          final String categoriePermis = user['permis'] ?? 'Non défini';
          final String photoUrl = user['user_profile']?['photo'] != null && user['user_profile']['photo'].isNotEmpty
              ? (user['user_profile']['photo'].startsWith('http') ? user['user_profile']['photo'] : 'http://192.168.11.243:8000${user['user_profile']['photo']}')
              : '';
          final bool hasPhoto = photoUrl.isNotEmpty;

          Color statutColor;
          switch (statut.toLowerCase()) {
            case 'actif':
              statutColor = Colors.green;
              break;
            case 'inactif':
              statutColor = Colors.red;
              break;
            case 'en_conge':
              statutColor = Colors.orange;
              break;
            default:
              statutColor = Colors.grey;
          }

          return Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: hasPhoto
                    ? DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.6),
                          BlendMode.darken,
                        ),
                      )
                    : null,
                gradient: !hasPhoto
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue[800]!, Colors.blue[400]!],
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                      backgroundColor: hasPhoto ? null : Colors.white30,
                      child: !hasPhoto ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          telephone,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.drive_eta, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          '$numeroPermis ($categoriePermis)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statutColor.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statut.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Colors.white),
                          tooltip: "Voir",
                          onPressed: () => _showUserDetailDialog(true, user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          tooltip: "Modifier",
                          onPressed: () => _showUserFormDialog(true, user: user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          tooltip: "Supprimer",
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirmer la suppression'),
                                content: const Text('Êtes-vous sûr de vouloir supprimer ce conducteur ?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Annuler'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      deleteUser(user['id'], true);
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
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
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
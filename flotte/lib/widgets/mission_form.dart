import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flotte/models/mission.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class MissionForm extends StatefulWidget {
  final Function(Mission) onSubmit;
  final Mission? mission;
  const MissionForm({super.key, required this.onSubmit, this.mission});

  @override
  State<MissionForm> createState() => _MissionFormState();
}

class _MissionFormState extends State<MissionForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _intituleController;
  late TextEditingController _codeController;
  late TextEditingController _lieuDepartController;
  late TextEditingController _lieuArriveeController;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  TimeOfDay? _heureDebut;
  TimeOfDay? _heureFin;
  String _statut = 'planifiee';
  late TextEditingController _commentaireController;
  double? _distanceKm;

  // Ajout pour véhicules et conducteurs
  List<Map<String, String>> _vehicules = [];
  List<Map<String, String>> _conducteurs = [];
  String? _selectedVehiculeId;
  String? _selectedConducteurId;
  bool _loadingVehicules = true;
  bool _loadingConducteurs = true;

  final FocusNode _lieuDepartFocusNode = FocusNode();
  final FocusNode _lieuArriveeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final m = widget.mission;
    _intituleController = TextEditingController(text: m?.intitule ?? '');
    _codeController = TextEditingController(text: m?.codeMission ?? '');
    _lieuDepartController = TextEditingController(text: m?.lieuDepart ?? '');
    _lieuArriveeController = TextEditingController(text: m?.lieuArrivee ?? '');
    _dateDebut = m?.dateDebut;
    _dateFin = m?.dateFin;
    _heureDebut = m?.dateDebut != null ? TimeOfDay(hour: m!.dateDebut.hour, minute: m.dateDebut.minute) : null;
    _heureFin = m?.dateFin != null ? TimeOfDay(hour: m!.dateFin.hour, minute: m.dateFin.minute) : null;
    _statut = m?.statut ?? 'planifiee';
    _commentaireController = TextEditingController(text: m?.commentaire ?? '');
    if (_dateDebut != null && _dateFin != null) {
      _fetchVehiculesDisponibles();
      _fetchConducteursDisponibles();
    } else {
      _fetchVehicules();
      _fetchConducteurs();
    }
  }

  Future<void> _fetchVehicules() async {
    setState(() { _loadingVehicules = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Token non trouvé');
      final response = await http.get(
        Uri.parse('http://192.168.11.243:8000/api/vehicles/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _vehicules = data.map<Map<String, String>>((vehicule) => {
            'id': vehicule['id'].toString(),
            'label': '${vehicule['marque']} ${vehicule['modele']}',
          }).toList();
          if (_selectedVehiculeId == null || !_vehicules.any((v) => v['id'] == _selectedVehiculeId)) {
            _selectedVehiculeId = _vehicules.isNotEmpty ? _vehicules.first['id'] : null;
          }
        });
      } else {
        throw Exception('Erreur API véhicules: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement véhicules: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _loadingVehicules = false; });
    }
  }

  Future<void> _fetchConducteurs() async {
    setState(() { _loadingConducteurs = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Token non trouvé');
      final response = await http.get(
        Uri.parse('http://192.168.11.243:8000/api/drivers/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _conducteurs = data.map<Map<String, String>>((conducteur) {
            final userProfile = conducteur['user_profile'] ?? {};
            final user = userProfile['user'] ?? {};
            final firstName = user['first_name'] ?? '';
            final lastName = user['last_name'] ?? '';
            final username = user['username'] ?? '';
            String label = '';
            if ((firstName + lastName).trim().isNotEmpty) {
              label = (firstName + ' ' + lastName).trim();
            } else if (username.isNotEmpty) {
              label = username;
            } else {
              label = 'Conducteur ${conducteur['id']}';
            }
            return {
              'id': conducteur['id'].toString(),
              'label': label,
            };
          }).toList();
          if (_selectedConducteurId == null || !_conducteurs.any((c) => c['id'] == _selectedConducteurId)) {
            _selectedConducteurId = _conducteurs.isNotEmpty ? _conducteurs.first['id'] : null;
          }
        });
      } else {
        throw Exception('Erreur API conducteurs: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement conducteurs: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _loadingConducteurs = false; });
    }
  }

  Future<void> _fetchVehiculesDisponibles() async {
    if (_dateDebut == null || _dateFin == null) return;
    setState(() { _loadingVehicules = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Token non trouvé');
      final url = Uri.parse('http://192.168.11.243:8000/api/available_vehicles/?date_debut=${_dateDebut!.toIso8601String()}&date_fin=${_dateFin!.toIso8601String()}');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _vehicules = data.map<Map<String, String>>((vehicule) => {
            'id': vehicule['id'].toString(),
            'label': '${vehicule['marque']} ${vehicule['modele']}',
          }).toList();
          if (_selectedVehiculeId == null || !_vehicules.any((v) => v['id'] == _selectedVehiculeId)) {
            _selectedVehiculeId = _vehicules.isNotEmpty ? _vehicules.first['id'] : null;
          }
        });
      } else {
        throw Exception('Erreur API véhicules: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement véhicules: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _loadingVehicules = false; });
    }
  }

  Future<void> _fetchConducteursDisponibles() async {
    if (_dateDebut == null || _dateFin == null) return;
    setState(() { _loadingConducteurs = true; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Token non trouvé');
      final url = Uri.parse('http://192.168.11.243:8000/api/available_drivers/?date_debut=${_dateDebut!.toIso8601String()}&date_fin=${_dateFin!.toIso8601String()}');
      final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _conducteurs = data.map<Map<String, String>>((conducteur) {
            final userProfile = conducteur['user_profile'] ?? {};
            final user = userProfile['user'] ?? {};
            final firstName = user['first_name'] ?? '';
            final lastName = user['last_name'] ?? '';
            final username = user['username'] ?? '';
            String label = '';
            if ((firstName + lastName).trim().isNotEmpty) {
              label = (firstName + ' ' + lastName).trim();
            } else if (username.isNotEmpty) {
              label = username;
            } else {
              label = 'Conducteur ${conducteur['id']}';
            }
            return {
              'id': conducteur['id'].toString(),
              'label': label,
            };
          }).toList();
          if (_selectedConducteurId == null || !_conducteurs.any((c) => c['id'] == _selectedConducteurId)) {
            _selectedConducteurId = _conducteurs.isNotEmpty ? _conducteurs.first['id'] : null;
          }
        });
      } else {
        throw Exception('Erreur API conducteurs: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement conducteurs: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _loadingConducteurs = false; });
    }
  }

  void _onDateChanged() {
    _fetchVehiculesDisponibles();
    _fetchConducteursDisponibles();
  }

  @override
  void dispose() {
    _intituleController.dispose();
    _codeController.dispose();
    _lieuDepartController.dispose();
    _lieuArriveeController.dispose();
    _commentaireController.dispose();
    _lieuDepartFocusNode.dispose();
    _lieuArriveeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isDebut) async {
    final initialDate = isDebut ? (_dateDebut ?? DateTime.now()) : (_dateFin ?? DateTime.now());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: isDebut ? (_heureDebut ?? TimeOfDay.now()) : (_heureFin ?? TimeOfDay.now()),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          );
        },
      );
      if (pickedTime != null) {
        setState(() {
          final dateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (isDebut) {
            _dateDebut = dateTime;
            _heureDebut = pickedTime;
          } else {
            _dateFin = dateTime;
            _heureFin = pickedTime;
          }
        });
        _onDateChanged();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _intituleController,
              decoration: const InputDecoration(labelText: 'Intitulé'),
              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Code mission'),
              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),
            TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                controller: _lieuDepartController,
                decoration: const InputDecoration(labelText: 'Lieu de départ (ville, adresse, etc.)'),
              ),
              suggestionsCallback: (pattern) async {
                if (pattern.length < 3) return [];
                final url = Uri.parse(
                  'https://nominatim.openstreetmap.org/search?q=$pattern&format=json&addressdetails=1&limit=5',
                );
                final response = await http.get(url, headers: {
                  'User-Agent': 'FlutterApp'
                });
                if (response.statusCode == 200) {
                  final List data = json.decode(response.body);
                  return data;
                } else {
                  return [];
                }
              },
              itemBuilder: (context, suggestion) {
                final displayName = suggestion['display_name'] ?? '';
                return ListTile(
                  title: Text(displayName),
                );
              },
              onSuggestionSelected: (suggestion) {
                _lieuDepartController.text = suggestion['display_name'] ?? '';
              },
              validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),
            TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                controller: _lieuArriveeController,
                decoration: const InputDecoration(labelText: 'Lieu d\'arrivée (ville, adresse, etc.)'),
              ),
              suggestionsCallback: (pattern) async {
                if (pattern.length < 3) return [];
                final url = Uri.parse(
                  'https://nominatim.openstreetmap.org/search?q=$pattern&format=json&addressdetails=1&limit=5',
                );
                final response = await http.get(url, headers: {
                  'User-Agent': 'FlutterApp'
                });
                if (response.statusCode == 200) {
                  final List data = json.decode(response.body);
                  return data;
                } else {
                  return [];
                }
              },
              itemBuilder: (context, suggestion) {
                final displayName = suggestion['display_name'] ?? '';
                return ListTile(
                  title: Text(displayName),
                );
              },
              onSuggestionSelected: (suggestion) {
                _lieuArriveeController.text = suggestion['display_name'] ?? '';
              },
              validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateTime(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date et heure début'),
                      child: Text(_dateDebut != null
                          ? DateFormat('yyyy-MM-dd HH:mm').format(_dateDebut!)
                          : 'Choisir'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateTime(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date et heure fin'),
                      child: Text(_dateFin != null
                          ? DateFormat('yyyy-MM-dd HH:mm').format(_dateFin!)
                          : 'Choisir'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Dropdown véhicules
            _loadingVehicules
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(),
                )
              : _vehicules.isEmpty
                  ? const Text('Aucun véhicule disponible')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedVehiculeId != null && !_vehicules.any((v) => v['id'] == _selectedVehiculeId))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '⚠️ Le véhicule lié à cette mission n\'existe plus.',
                              style: const TextStyle(color: Colors.orange, fontSize: 13),
                            ),
                          ),
                        DropdownButtonFormField<String>(
                          value: _vehicules.isEmpty
                            ? null
                            : (_selectedVehiculeId != null && _vehicules.any((v) => v['id'] == _selectedVehiculeId))
                                ? _selectedVehiculeId
                                : _vehicules.first['id'],
                          decoration: const InputDecoration(labelText: 'Véhicule'),
                          items: _vehicules
                              .map((v) => DropdownMenuItem(
                                    value: v['id'],
                                    child: Text(v['label'] ?? ''),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedVehiculeId = v),
                          validator: (v) => v == null ? 'Sélectionnez un véhicule' : null,
                        ),
                      ],
                    ),
            const SizedBox(height: 12),
            // Dropdown conducteurs
            _loadingConducteurs
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(),
                )
              : _conducteurs.isEmpty
                  ? const Text('Aucun conducteur disponible')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedConducteurId != null && !_conducteurs.any((c) => c['id'] == _selectedConducteurId))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '⚠️ Le conducteur lié à cette mission n\'existe plus.',
                              style: const TextStyle(color: Colors.orange, fontSize: 13),
                            ),
                          ),
                        DropdownButtonFormField<String>(
                          value: _conducteurs.isEmpty
                            ? null
                            : (_selectedConducteurId != null && _conducteurs.any((c) => c['id'] == _selectedConducteurId))
                                ? _selectedConducteurId
                                : _conducteurs.first['id'],
                          decoration: const InputDecoration(labelText: 'Conducteur'),
                          items: _conducteurs
                              .map((c) => DropdownMenuItem(
                                    value: c['id'],
                                    child: Text(c['label'] ?? ''),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedConducteurId = v),
                          validator: (v) => v == null ? 'Sélectionnez un conducteur' : null,
                        ),
                      ],
                    ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentaireController,
              decoration: const InputDecoration(labelText: 'Commentaire'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState?.validate() != true) return;
                if (_dateDebut == null || _dateFin == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez choisir les dates.')),
                  );
                  return;
                }
                final mission = Mission(
                  id: widget.mission?.id ?? '',
                  codeMission: _codeController.text.trim(),
                  intitule: _intituleController.text.trim(),
                  lieuDepart: _lieuDepartController.text.trim(),
                  lieuArrivee: _lieuArriveeController.text.trim(),
                  dateDebut: _dateDebut!,
                  dateFin: _dateFin!,
                  commentaire: _commentaireController.text.trim().isEmpty
                      ? null
                      : _commentaireController.text.trim(),
                  vehicleId: _selectedVehiculeId ?? '',
                  driverId: _selectedConducteurId ?? '',
                );
                try {
                  await widget.onSubmit(mission);
                } catch (e) {
                  print('ERREUR FLUTTER: $e');
                  print('TYPE ERREUR: \'${e.runtimeType}\'');
                  String message = 'Erreur inconnue';
                  try {
                    final data = json.decode(e.toString().replaceFirst('Exception: ', ''));
                    if (data is Map && data.values.isNotEmpty) {
                      message = data.values.map((v) => v.toString()).join('\n');
                    } else if (data is String) {
                      message = data;
                    }
                  } catch (err) {
                    print('ERREUR PARSING: $err');
                    message = e.toString();
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(widget.mission == null ? 'Créer' : 'Mettre à jour'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PositionSenderService with ChangeNotifier, WidgetsBindingObserver {
  Timer? _timer;
  bool _isRunning = false;
  String? _lastStatus;

  // Pour feedback visuel
  String? get lastStatus => _lastStatus;

  // Récupérer l'ID conducteur depuis les préférences
  int get conducteurId {
    final prefs = SharedPreferences.getInstance();
    // Ceci doit être asynchrone dans la méthode d'envoi réelle
    // Ici, on retourne une valeur par défaut pour la déclaration
    return 0;
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _sendPosition());
    _sendPosition(); // Envoi immédiat au démarrage
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed && _isRunning) {
      _timer = Timer.periodic(const Duration(seconds: 10), (_) => _sendPosition());
      _sendPosition();
    }
  }

  Future<void> _sendPosition() async {
    double latitude;
    double longitude;
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      latitude = double.parse(position.latitude.toStringAsFixed(6));
      longitude = double.parse(position.longitude.toStringAsFixed(6));
    } catch (e) {
      // Fallback position simulée (Paris)
      latitude = 48.856613;
      longitude = 2.352222;
      _lastStatus = 'Position simulée utilisée';
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final driverId = prefs.getInt('driver_id');
      if (token == null) {
        _lastStatus = 'Token absent, authentification requise';
        notifyListeners();
        return;
      }
      if (driverId == null || driverId == 0) {
        _lastStatus = 'ID conducteur non trouvé';
        notifyListeners();
        return;
      }
      final backendUrl = prefs.getString('backend_url') ?? 'http://localhost:8000';
      if (backendUrl.isEmpty) {
        _lastStatus = 'URL backend non configurée';
        notifyListeners();
        return;
      }
      final response = await http.post(
        Uri.parse('$backendUrl/api/positions/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'driver': driverId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        _lastStatus = 'Position envoyée à $latitude, $longitude';
        // Enregistrer la dernière position dans SharedPreferences
        await prefs.setDouble('last_latitude', latitude);
        await prefs.setDouble('last_longitude', longitude);
      } else {
        _lastStatus = 'Erreur d\'envoi: \\${response.statusCode}';
      }
    } catch (e) {
      _lastStatus = 'Erreur réseau';
    }
    notifyListeners();
  }
} 
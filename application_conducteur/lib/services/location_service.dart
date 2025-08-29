import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static Future<bool> handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  static Future<void> sendPosition(int driverId, String token, String backendUrl) async {
    print('LOG: Début envoi position');
    bool hasPermission = await handleLocationPermission();
    if (!hasPermission) {
      print('LOG: Permission localisation refusée');
      return;
    }

    print('LOG: driverId=$driverId, token=${token.substring(0, 8)}..., backendUrl=$backendUrl');

    double latitude;
    double longitude;

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      latitude = position.latitude;
      longitude = position.longitude;
      print('LOG: Position récupérée: lat=$latitude, lon=$longitude');
    } catch (e) {
      // Si la géolocalisation échoue (ex: permissions refusées), on simule une position
      latitude = 5.3484;
      longitude = -4.0276;
      print('LOG: Erreur géolocalisation, position simulée: lat=$latitude, lon=$longitude');
    }

    // Récupérer l'ID du conducteur depuis les préférences
    final prefs = await SharedPreferences.getInstance();
    driverId = prefs.getInt('driver_id') ?? driverId;
    print('LOG: Envoi position pour driverId=$driverId, lat=$latitude, lon=$longitude');

    final url = Uri.parse('$backendUrl/api/positions/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'driver': driverId,
        'latitude': double.parse(latitude.toStringAsFixed(6)),
        'longitude': double.parse(longitude.toStringAsFixed(6)),
      }),
    );

    print('LOG: POST /positions/ => code=${response.statusCode}, body=${response.body}');

    if (response.statusCode == 201) {
      print('LOG: Position envoyée avec succès');
    } else {
      print('LOG: Erreur lors de l\'envoi de la position : ${response.body}');
    }
  }
} 
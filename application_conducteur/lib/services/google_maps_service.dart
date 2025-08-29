import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsService {
  static const String _apiKey = 'AlzaSyCCI7jqy90ePLR00IHCXAVWOxDSri_BgDs';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';

  // Obtenir l'itinéraire entre deux points
  static Future<Map<String, dynamic>> getDirections({
    required LatLng origin,
    required LatLng destination,
    String? waypoints,
    String mode = 'driving',
  }) async {
    final url = Uri.parse(
      '$_baseUrl/directions/json?'
      'origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '${waypoints != null ? '&waypoints=$waypoints' : ''}'
      '&mode=$mode'
      '&key=$_apiKey'
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data;
        } else {
          throw Exception('Erreur Google Maps: ${data['status']}');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'itinéraire: $e');
    }
  }

  // Obtenir la distance et la durée entre deux points
  static Future<Map<String, dynamic>> getDistanceMatrix({
    required LatLng origin,
    required LatLng destination,
    String mode = 'driving',
  }) async {
    final url = Uri.parse(
      '$_baseUrl/distancematrix/json?'
      'origins=${origin.latitude},${origin.longitude}'
      '&destinations=${destination.latitude},${destination.longitude}'
      '&mode=$mode'
      '&key=$_apiKey'
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data;
        } else {
          throw Exception('Erreur Google Maps: ${data['status']}');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la distance: $e');
    }
  }

  // Calculer la distance entre deux adresses
  static Future<Map<String, dynamic>> calculateDistanceBetweenAddresses({
    required String origin,
    required String destination,
    String mode = 'driving',
  }) async {
    try {
      // Géocoder les adresses pour obtenir les coordonnées
      final originGeocode = await geocode(origin);
      final destinationGeocode = await geocode(destination);
      
      if (originGeocode['results'].isEmpty || destinationGeocode['results'].isEmpty) {
        throw Exception('Impossible de géocoder une des adresses');
      }
      
      final originLocation = LatLng(
        originGeocode['results'][0]['geometry']['location']['lat'].toDouble(),
        originGeocode['results'][0]['geometry']['location']['lng'].toDouble(),
      );
      
      final destinationLocation = LatLng(
        destinationGeocode['results'][0]['geometry']['location']['lat'].toDouble(),
        destinationGeocode['results'][0]['geometry']['location']['lng'].toDouble(),
      );
      
      // Obtenir la distance et la durée
      final distanceMatrix = await getDistanceMatrix(
        origin: originLocation,
        destination: destinationLocation,
        mode: mode,
      );
      
      if (distanceMatrix['rows'].isNotEmpty && 
          distanceMatrix['rows'][0]['elements'].isNotEmpty) {
        final element = distanceMatrix['rows'][0]['elements'][0];
        
        if (element['status'] == 'OK') {
          return {
            'distance': element['distance']['text'],
            'distance_meters': element['distance']['value'],
            'duration': element['duration']['text'],
            'duration_seconds': element['duration']['value'],
            'origin_location': originLocation,
            'destination_location': destinationLocation,
          };
        } else {
          throw Exception('Impossible de calculer la distance: ${element['status']}');
        }
      } else {
        throw Exception('Aucune route trouvée entre les points');
      }
    } catch (e) {
      throw Exception('Erreur lors du calcul de la distance: $e');
    }
  }

  // Géocodage inverse (coordonnées vers adresse)
  static Future<Map<String, dynamic>> reverseGeocode(LatLng position) async {
    final url = Uri.parse(
      '$_baseUrl/geocode/json?'
      'latlng=${position.latitude},${position.longitude}'
      '&key=$_apiKey'
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data;
        } else {
          throw Exception('Erreur Google Maps: ${data['status']}');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors du géocodage inverse: $e');
    }
  }

  // Géocodage (adresse vers coordonnées)
  static Future<Map<String, dynamic>> geocode(String address) async {
    final url = Uri.parse(
      '$_baseUrl/geocode/json?'
      'address=${Uri.encodeComponent(address)}'
      '&key=$_apiKey'
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data;
        } else {
          throw Exception('Erreur Google Maps: ${data['status']}');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors du géocodage: $e');
    }
  }

  // Obtenir les lieux à proximité
  static Future<Map<String, dynamic>> getNearbyPlaces({
    required LatLng location,
    required String type,
    int radius = 5000,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/place/nearbysearch/json?'
      'location=${location.latitude},${location.longitude}'
      '&radius=$radius'
      '&type=$type'
      '&key=$_apiKey'
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data;
        } else {
          throw Exception('Erreur Google Maps: ${data['status']}');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la recherche de lieux: $e');
    }
  }

  // Obtenir les détails d'un lieu
  static Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      '$_baseUrl/place/details/json?'
      'place_id=$placeId'
      '&key=$_apiKey'
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data;
        } else {
          throw Exception('Erreur Google Maps: ${data['status']}');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des détails: $e');
    }
  }

  // Calculer l'itinéraire pour une mission
  static Future<Map<String, dynamic>> calculateMissionRoute({
    required String origin,
    required String destination,
    String? waypoints,
  }) async {
    try {
      // Géocoder l'origine
      final originGeocode = await geocode(origin);
      final originLocation = LatLng(
        originGeocode['results'][0]['geometry']['location']['lat'].toDouble(),
        originGeocode['results'][0]['geometry']['location']['lng'].toDouble(),
      );

      // Géocoder la destination
      final destGeocode = await geocode(destination);
      final destLocation = LatLng(
        destGeocode['results'][0]['geometry']['location']['lat'].toDouble(),
        destGeocode['results'][0]['geometry']['location']['lng'].toDouble(),
      );

      // Obtenir l'itinéraire
      final directions = await getDirections(
        origin: originLocation,
        destination: destLocation,
        waypoints: waypoints,
      );

      // Obtenir la matrice de distance
      final distanceMatrix = await getDistanceMatrix(
        origin: originLocation,
        destination: destLocation,
      );

      return {
        'directions': directions,
        'distance_matrix': distanceMatrix,
        'origin_location': originLocation,
        'destination_location': destLocation,
      };
    } catch (e) {
      throw Exception('Erreur lors du calcul de l\'itinéraire: $e');
    }
  }

  // Obtenir la position actuelle
  static Future<LatLng> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la position: $e');
    }
  }

  // Formater la durée en format lisible
  static String formatDuration(String durationText) {
    // Google Maps retourne "1 hour 30 mins" ou "45 mins"
    return durationText.replaceAll(' hour', 'h').replaceAll(' mins', 'min');
  }

  // Formater la distance en format lisible
  static String formatDistance(String distanceText) {
    // Google Maps retourne "15.2 km" ou "2.1 km"
    return distanceText;
  }
}

// Utilisation de la classe LatLng de Google Maps Flutter 
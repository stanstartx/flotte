import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'http_client.dart';

class TripsService {
  static const String basePath = 'drivers';

  static Future<List<Map<String, dynamic>>> fetchDriverTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final driverId = prefs.getInt('driver_id');
    if (token == null) throw Exception('Token non trouvé');
    if (driverId == null) throw Exception('ID conducteur non trouvé');

    final dio = HttpClient.instance;
    try {
      final Response response = await dio.get(
        '/$basePath/$driverId/trips/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final List data = response.data as List;
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      throw Exception('Erreur fetch trips: ${response.statusCode}');
    } catch (e, st) {
      debugPrint('TripsService.fetchDriverTrips error: $e\n$st');
      rethrow;
    }
  }
}



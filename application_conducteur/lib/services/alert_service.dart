import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'http_client.dart';

class AlertService {
  static const String basePath = 'alerts/';

  static Future<List<Map<String, dynamic>>> fetchAlerts({bool onlyMine = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final driverId = prefs.getInt('driver_id');
    if (token == null) throw Exception('Token non trouvé');

    final dio = HttpClient.instance;
    try {
      final String path = onlyMine ? '/$basePath/mes_alertes/' : '/$basePath';
      final Response response = await dio.get(
        path,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final List data = response.data as List;
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      throw Exception('Erreur fetch alertes: ${response.statusCode}');
    } catch (e, st) {
      debugPrint('AlertService.fetchAlerts error: $e\n$st');
      rethrow;
    }
  }
}



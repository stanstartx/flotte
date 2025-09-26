import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'http_client.dart';

class StatsService {
  static Future<Map<String, dynamic>> fetchDashboardStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Token non trouvé');

    final dio = HttpClient.instance;
    try {
      final response = await dio.get(
        '/dashboard/stats/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception('Erreur stats: ${response.statusCode}');
    } catch (e, st) {
      debugPrint('StatsService.fetchDashboardStats error: $e\n$st');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRecentActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Token non trouvé');

    final dio = HttpClient.instance;
    try {
      final response = await dio.get(
        '/dashboard/recent-activities/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final List data = response.data as List;
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      throw Exception('Erreur activités: ${response.statusCode}');
    } catch (e, st) {
      debugPrint('StatsService.fetchRecentActivities error: $e\n$st');
      rethrow;
    }
  }
}



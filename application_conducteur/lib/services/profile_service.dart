import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'http_client.dart';
import 'dart:io';

class ProfileService {
  static Future<Map<String, dynamic>> fetchMyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Token non trouvé');

    final dio = HttpClient.instance;
    try {
      final Response response = await dio.get(
        '/userprofiles/my_profile/',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data as Map);
        try {
          final prefs = await SharedPreferences.getInstance();
          final id = data['id'] as int?;
          if (id != null) {
            await prefs.setInt('profile_id', id);
          }
        } catch (_) {}
        return data;
      }
      throw Exception('Erreur fetch profil: ${response.statusCode}');
    } catch (e, st) {
      debugPrint('ProfileService.fetchMyProfile error: $e\n$st');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> fetchAssignedVehicle() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final driverId = prefs.getInt('driver_id');
    if (token == null) throw Exception('Token non trouvé');
    if (driverId == null) throw Exception('ID conducteur non trouvé');

    final dio = HttpClient.instance;
    try {
      final Response response = await dio.get(
        '/conducteur/vehicules/',
        queryParameters: {'driver_id': driverId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        if (response.data is List && (response.data as List).isNotEmpty) {
          return Map<String, dynamic>.from((response.data as List).first as Map);
        }
        return <String, dynamic>{};
      }
      throw Exception('Erreur fetch véhicule: ${response.statusCode}');
    } catch (e, st) {
      debugPrint('ProfileService.fetchAssignedVehicle error: $e\n$st');
      rethrow;
    }
  }

  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Token non trouvé');

    final dio = HttpClient.instance;
    final response = await dio.post(
      '/auth/change-password/',
      data: {'old_password': oldPassword, 'new_password': newPassword},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Echec changement mot de passe: ${response.statusCode}');
    }
  }

  static Future<String?> uploadProfilePhoto(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    int? profileId = prefs.getInt('profile_id');
    if (token == null) throw Exception('Token non trouvé');
    if (profileId == null) {
      // Résoudre via /userprofiles/my_profile/
      try {
        final me = await fetchMyProfile();
        profileId = me['id'] as int?;
        if (profileId != null) {
          await prefs.setInt('profile_id', profileId!);
        }
      } catch (_) {}
    }
    if (profileId == null) throw Exception('ID profil non trouvé');

    final dio = HttpClient.instance;
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    final response = await dio.post(
      '/userprofiles/$profileId/upload_photo/',
      data: formData,
      options: Options(
        method: 'POST',
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );
    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      return data['avatar']?.toString();
    }
    throw Exception('Echec upload photo: ${response.statusCode}');
  }
}



import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'http_client.dart';

class DocumentsService {
  static const String basePath = 'documents/';

  static Future<List<Map<String, dynamic>>> fetchDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final driverId = prefs.getInt('driver_id');
    if (token == null) throw Exception('Token non trouvé');

    final dio = HttpClient.instance;
    try {
      final Response response = await dio.get(
        '/$basePath',
        // Essayez de filtrer côté API si supporté
        queryParameters: driverId != null ? {'driver': driverId} : null,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        final List data = response.data as List;
        return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      throw Exception('Erreur fetch documents: ${response.statusCode}');
    } catch (e, st) {
      debugPrint('DocumentsService.fetchDocuments error: $e\n$st');
      rethrow;
    }
  }

  static Future<void> uploadDocument({
    required File file,
    String? title,
    String? expiration,
    String? status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Token non trouvé');

    final dio = HttpClient.instance;
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      if (title != null) 'title': title,
      if (expiration != null) 'expiration': expiration,
      if (status != null) 'status': status,
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final Response response = await dio.post(
      '/$basePath',
      data: formData,
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Echec upload document: ${response.statusCode}');
    }
  }
}



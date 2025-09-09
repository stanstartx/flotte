// lib/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'http_client.dart';

class AuthService {
  Future<void> login(String email, String password) async {
    try {
      final dio = HttpClient.instance;
      final Response response = await dio.post(
        'auth/login/',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final roles = (data['user']?['roles'] as List?) ?? [];
      final prefs = await SharedPreferences.getInstance();

      if (roles.contains('conducteur')) {
        await prefs.setString('token', data['access'] as String);
        await prefs.setString('refresh', data['refresh'] as String);
        await prefs.setString('role', 'conducteur');

        final driverId = data['user']?['driver_id'];
        if (driverId is int) {
          await prefs.setInt('driver_id', driverId);
        }
      } else {
        throw Exception(
          "Vous n'êtes pas autorisé à accéder à cette application (rôle non conducteur).",
        );
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['error'] ?? 'Erreur de connexion')
          : 'Erreur de connexion';
      throw Exception(message);
    }
  }

  Future<void> register(String email, String password) async {
    try {
      final dio = HttpClient.instance;
      final Response response = await dio.post(
        'auth/register/',
        data: {
          'email': email,
          'password': password,
        },
      );

      // On suppose que l'API renvoie aussi access/refresh token après inscription
      final data = response.data as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('token', data['access'] as String);
      await prefs.setString('refresh', data['refresh'] as String);

      if (data['user']?['roles'] != null) {
        final roles = (data['user']?['roles'] as List?) ?? [];
        if (roles.contains('conducteur')) {
          await prefs.setString('role', 'conducteur');

          final driverId = data['user']?['driver_id'];
          if (driverId is int) {
            await prefs.setInt('driver_id', driverId);
          }
        }
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['error'] ?? 'Erreur lors de l\'inscription')
          : 'Erreur lors de l\'inscription';
      throw Exception(message);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh');
    await prefs.remove('role');
    await prefs.remove('driver_id');
  }
}

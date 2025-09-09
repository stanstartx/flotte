import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'http_client.dart';

class AuthService {
  Future<void> login(String email, String password) async {
    try {
      final dio = HttpClient.instance;
      final Response response = await dio.post(
        '/api/auth/login/',  // corrigé
        data: {
          'username': email,  // ⚠️ changer en 'email' si backend configuré
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();

      // Sauvegarde des tokens
      final accessToken = data['access'] as String?;
      final refreshToken = data['refresh'] as String?;
      if (accessToken != null) {
        await prefs.setString('token', accessToken);
      } else {
        throw Exception('Aucun token d\'accès reçu.');
      }
      if (refreshToken != null) {
        await prefs.setString('refresh', refreshToken);
      }

      // Sauvegarde du rôle (si renvoyé par l’API)
      final roles = data['user']?['roles'] as List<dynamic>?;
      final role = roles?.isNotEmpty == true ? roles![0] as String : null;
      if (role != null) {
        await prefs.setString('role', role);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Email ou mot de passe incorrect.');
      } else if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Délai de connexion dépassé.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Impossible de se connecter au serveur.');
      } else {
        throw Exception('Erreur réseau : ${e.message}');
      }
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh');
    await prefs.remove('role');
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }
}

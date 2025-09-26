import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'http_client.dart';

class AuthService {
  Future<void> login(String email, String password) async {
    try {
      final dio = HttpClient.instance;

      print('Tentative de connexion à : ${AppConfig.apiBaseUrl}/auth/login/');
      print('Email: $email');

      final Response response = await dio.post(
        '/auth/login/', // baseUrl déjà défini dans HttpClient
        data: {
          'username': email, // backend attend "username"
          'password': password,
        },
        options: Options(
          validateStatus: (status) =>
              status != null && status < 500, // autoriser erreurs < 500
        ),
      );

      print('Réponse du serveur: ${response.statusCode}');
      print('Données: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final roles = (data['user']?['roles'] as List?) ?? [];
        final prefs = await SharedPreferences.getInstance();

        if (roles.contains('conducteur')) {
          final access = data['access'] as String?;
          final refresh = data['refresh'] as String?;

          if (access == null || refresh == null) {
            throw Exception("Réponse serveur invalide (tokens manquants).");
          }

          // Stocker dans SharedPreferences
          await prefs.setString('token', access);
          await prefs.setString('refresh', refresh);
          await prefs.setString('role', 'conducteur');

          final driverId = data['user']?['driver_id'];
          if (driverId is int) {
            await prefs.setInt('driver_id', driverId);
          }

          // Enregistrer profile_id si présent dans verify ultérieur
          try {
            final verify = await dio.get('/auth/verify/',
                options: Options(headers: {'Authorization': 'Bearer $access'}));
            final profileId = verify.data?['user']?['profile_id'] as int?;
            if (profileId != null) {
              await prefs.setInt('profile_id', profileId);
            }
          } catch (_) {}

          // Stocker en mémoire globale
          AppConfig.token = access;

          print('Connexion réussie (conducteur ID: $driverId)');
        } else {
          throw Exception(
            "Accès refusé : rôle non conducteur.",
          );
        }
      } else {
        final errorMessage = response.data is Map<String, dynamic>
            ? (response.data['error'] ?? 'Erreur de connexion')
            : 'Erreur de connexion (${response.statusCode})';
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      print('Erreur Dio: ${e.type} - ${e.message}');
      print('Réponse: ${e.response?.data}');

      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Timeout de connexion. Vérifiez votre réseau.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
            'Impossible de joindre le serveur. Vérifiez qu’il est démarré.');
      }

      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['error'] ?? 'Erreur de connexion')
          : 'Erreur de connexion: ${e.message}';
      throw Exception(message);
    } catch (e) {
      print('Erreur générale: $e');
      throw Exception('Erreur inattendue: $e');
    }
  }

  Future<void> register(String email, String password) async {
    try {
      final dio = HttpClient.instance;
      final Response response = await dio.post(
        '/auth/register/',
        data: {
          'email': email,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();

      final access = data['access'] as String?;
      final refresh = data['refresh'] as String?;

      if (access != null && refresh != null) {
        await prefs.setString('token', access);
        await prefs.setString('refresh', refresh);

        AppConfig.token = access;

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
      } else {
        throw Exception("Réponse serveur invalide (tokens manquants).");
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
    AppConfig.token = "";
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      AppConfig.token = token;
      return true;
    }
    return false;
  }
}

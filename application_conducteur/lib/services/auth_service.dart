import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Remplace l'URL par celle de ton backend si besoin
  static const String apiUrl = 'http://localhost:8000/api';

  Future<void> login(String username, String password) async {
    final url = Uri.parse('$apiUrl/auth/login/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      final roles = data['user']?['roles'] ?? [];
      if (roles.contains('conducteur')) {
        await prefs.setString('token', data['access']);
        await prefs.setString('role', 'conducteur');
        if (data['user']?['driver_id'] != null) {
          await prefs.setInt('driver_id', data['user']['driver_id']);
        }
        // Tu peux stocker d'autres infos utilisateur ici si besoin
      } else {
        throw Exception("Vous n'êtes pas autorisé à accéder à cette application (rôle non conducteur).");
      }
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Erreur de connexion');
    }
  }
} 
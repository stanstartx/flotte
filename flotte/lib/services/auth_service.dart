import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
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
      await prefs.setString('token', data['access']);
      // Stocker le rôle principal si présent
      if (data['user'] != null && data['user']['roles'] != null && data['user']['roles'].isNotEmpty) {
        await prefs.setString('role', data['user']['roles'][0]);
      }
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Erreur de connexion');
    }
  }
}

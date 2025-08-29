import 'package:flotte/models/mission.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class MissionService {
  MissionService();
  // Ajoute ici les méthodes nécessaires plus tard

  void creerMission(String titre) {
    // Implémentation à venir
  }

  Future<List<Mission>> getMissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Token non trouvé');
      const backendUrl = 'http://localhost:8000/api/missions/'; // À adapter si besoin
      final response = await http.get(
        Uri.parse(backendUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Mission.fromJson(json)).toList();
      } else {
        throw Exception('Erreur API: \\${response.statusCode} \\${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Mission>> getMissionsByStatus(String status) async {
    // Retourne une liste fictive filtrée
    return [];
  }

  Future<void> createMission(Mission mission) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Token non trouvé');
      const backendUrl = 'http://localhost:8000/api/missions/'; // À adapter si besoin
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(mission.toJson()),
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        // Mission créée avec succès
        return;
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateMission(Mission mission) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Token non trouvé');
      final backendUrl = 'http://localhost:8000/api/missions/${mission.id}/';
      final response = await http.put(
        Uri.parse(backendUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(mission.toJson()),
      );
      if (response.statusCode == 200) {
        // Mission modifiée avec succès
        return;
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteMission(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Token non trouvé');
      final backendUrl = 'http://localhost:8000/api/missions/$id/';
      final response = await http.delete(
        Uri.parse(backendUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 204 || response.statusCode == 200) {
        // Mission supprimée avec succès
        return;
      } else {
        throw Exception('Erreur API: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

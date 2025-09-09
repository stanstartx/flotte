import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'error_handler_service.dart';
import 'cache_service.dart';
import '../config.dart';
import 'http_client.dart';

class MissionService {
  static const String basePath = 'conducteur/missions/';

  // Récupérer les missions du conducteur connecté avec cache et gestion d'erreurs
  static Future<List<Map<String, dynamic>>> fetchMissions({bool forceRefresh = false}) async {
    return ErrorHandlerService.handleWithRetry(
      operation: () async {
        return await CacheService.getOrFetchList<Map<String, dynamic>>(
          key: CacheKeys.missions,
          fetchFunction: _fetchMissionsFromAPI,
          expiration: const Duration(minutes: 5),
          forceRefresh: forceRefresh,
        );
      },
      maxRetries: 3,
      customErrorMessage: 'Impossible de récupérer les missions',
    );
  }

  // Récupérer les missions depuis l'API
  static Future<List<Map<String, dynamic>>> _fetchMissionsFromAPI() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final driverId = prefs.getInt('driver_id');
    
    if (token == null) throw Exception('Token non trouvé');
    if (driverId == null) throw Exception('ID conducteur non trouvé');
    
    final dio = HttpClient.instance;
    final response = await dio.get(
      '$basePath',
      queryParameters: {'conducteur': driverId},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data as List<dynamic>;
      return List<Map<String, dynamic>>.from(data.map((m) {
        final map = Map<String, dynamic>.from(m);
        map['reponse_conducteur'] = m['reponse_conducteur'];
        return map;
      }));
    } else if (response.statusCode == 401) {
      throw Exception('Session expirée. Veuillez vous reconnecter.');
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  }

  // Accepter une mission avec gestion d'erreurs
  static Future<void> accepterMission(int missionId) async {
    return ErrorHandlerService.handleWithRetry(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) throw Exception('Token non trouvé');
        
        final dio = HttpClient.instance;
        final response = await dio.post('$basePath$missionId/accepter/');
        
        if (response.statusCode == 200) {
          // Invalider le cache des missions
          await CacheService.removeData(CacheKeys.missions);
          return;
        } else if (response.statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        } else {
          throw Exception('Erreur lors de l\'acceptation: ${response.statusCode}');
        }
      },
      maxRetries: 2,
      customErrorMessage: 'Impossible d\'accepter la mission',
    );
  }

  // Refuser une mission avec gestion d'erreurs
  static Future<void> refuserMission(int missionId) async {
    return ErrorHandlerService.handleWithRetry(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) throw Exception('Token non trouvé');
        
        final dio = HttpClient.instance;
        final response = await dio.post('$basePath$missionId/refuser/');
        
        if (response.statusCode == 200) {
          // Invalider le cache des missions
          await CacheService.removeData(CacheKeys.missions);
          return;
        } else if (response.statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        } else {
          throw Exception('Erreur lors du refus: ${response.statusCode}');
        }
      },
      maxRetries: 2,
      customErrorMessage: 'Impossible de refuser la mission',
    );
  }

  // Terminer une mission
  static Future<void> terminerMission(int missionId, {String? commentaire}) async {
    return ErrorHandlerService.handleWithRetry(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) throw Exception('Token non trouvé');
        
        final dio = HttpClient.instance;
        final body = <String, dynamic>{};
        if (commentaire != null) {
          body['commentaire'] = commentaire;
        }
        final response = await dio.post('$basePath$missionId/terminer/', data: body);
        
        if (response.statusCode == 200) {
          // Invalider le cache des missions
          await CacheService.removeData(CacheKeys.missions);
          return;
        } else if (response.statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        } else {
          throw Exception('Erreur lors de la finalisation: ${response.statusCode}');
        }
      },
      maxRetries: 2,
      customErrorMessage: 'Impossible de terminer la mission',
    );
  }

  // Obtenir les statistiques des missions
  static Future<Map<String, int>> getMissionStats() async {
    final missions = await fetchMissions();
    final stats = <String, int>{
      'total': missions.length,
      'a_faire': 0,
      'acceptees': 0,
      'refusees': 0,
      'terminees': 0,
    };
    
    for (final mission in missions) {
      final statut = mission['statut']?.toString().toLowerCase() ?? '';
      final reponse = mission['reponse_conducteur']?.toString().toLowerCase() ?? '';
      
      if (statut == 'terminee') {
        stats['terminees'] = (stats['terminees'] ?? 0) + 1;
      } else if (reponse == 'acceptee') {
        stats['acceptees'] = (stats['acceptees'] ?? 0) + 1;
      } else if (reponse == 'refusee') {
        stats['refusees'] = (stats['refusees'] ?? 0) + 1;
      } else {
        stats['a_faire'] = (stats['a_faire'] ?? 0) + 1;
      }
    }
    
    return stats;
  }

  // Rafraîchir les missions
  static Future<void> refreshMissions() async {
    await CacheService.removeData(CacheKeys.missions);
    await fetchMissions(forceRefresh: true);
  }
} 
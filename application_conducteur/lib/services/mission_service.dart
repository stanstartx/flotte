import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'error_handler_service.dart';
import 'cache_service.dart';
import '../config.dart';
import 'http_client.dart';

class MissionService {
  static const String basePath = 'missions/';

  // Récupérer les missions du conducteur connecté
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

    debugPrint('Fetching missions for driver_id: $driverId');

    final dio = HttpClient.instance;
    try {
      final response = await dio.get(
        '/$basePath',
        queryParameters: {'driver': driverId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        debugPrint('API Response: $data');
        return List<Map<String, dynamic>>.from(data.map((m) {
          final map = Map<String, dynamic>.from(m);
          map['titre'] = m['raison'] ?? 'Mission ${m['id']}';
          map['date'] = m['date_depart'] != null
              ? DateTime.parse(m['date_depart']).toString().substring(0, 10)
              : '';
          map['heure'] = m['date_depart'] != null
              ? DateTime.parse(m['date_depart']).toString().substring(11, 16)
              : '';
          map['depart'] = m['lieu_depart'] ?? '';
          map['arrivee'] = m['lieu_arrivee'] ?? '';
          map['description'] = m['raison'] ?? '';
          map['statut'] = _mapStatut(m['statut'] ?? 'en_attente');
          map['reponse_conducteur'] = m['reponse_conducteur'] ?? 'en_attente';
          map['id'] = m['id'];
          return map;
        }));
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        throw Exception('Erreur serveur: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      debugPrint('Error fetching missions: $e');
      rethrow;
    }
  }

  // Mapper les statuts pour l'affichage dans l'app conducteur
  static String _mapStatut(String apiStatut) {
    switch (apiStatut.toLowerCase()) {
      case 'en_attente':
      case 'planifiee':
        return 'À faire';
      case 'acceptee':
        return 'Acceptée';
      case 'en_cours':
        return 'En cours';
      case 'refusee':
        return 'Refusée';
      case 'terminee':
        return 'Terminée';
      default:
        return 'À faire';
    }
  }

  // Fetch une mission unique
  static Future<Map<String, dynamic>> fetchSingleMission(int missionId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Token non trouvé');

    final dio = HttpClient.instance;
    final response = await dio.get(
      '/$basePath$missionId/',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    if (response.statusCode == 200) {
      final map = Map<String, dynamic>.from(response.data);
      map['titre'] = map['raison'] ?? 'Mission ${map['id']}';
      map['date'] = map['date_depart'] != null
          ? DateTime.parse(map['date_depart']).toString().substring(0, 10)
          : '';
      map['heure'] = map['date_depart'] != null
          ? DateTime.parse(map['date_depart']).toString().substring(11, 16)
          : '';
      map['depart'] = map['lieu_depart'] ?? '';
      map['arrivee'] = map['lieu_arrivee'] ?? '';
      map['description'] = map['raison'] ?? '';
      map['statut'] = _mapStatut(map['statut'] ?? 'en_attente');
      map['reponse_conducteur'] = map['reponse_conducteur'] ?? 'en_attente';
      return map;
    } else {
      throw Exception('Erreur fetch mission: ${response.statusCode}');
    }
  }

  // Accepter une mission
  static Future<void> accepterMission(int missionId) async {
    return ErrorHandlerService.handleWithRetry(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) throw Exception('Token non trouvé');

        final dio = HttpClient.instance;
        final response = await dio.post(
          'http://192.168.11.243:8000/api/$basePath$missionId/accepter/',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );

        debugPrint('Réponse accepterMission ID $missionId: ${response.statusCode} - ${response.data}');
        if (response.statusCode == 200) {
          await CacheService.removeData(CacheKeys.missions);
          debugPrint('Cache missions vidé après acceptation');
          await fetchMissions(forceRefresh: true); // Forcer le rafraîchissement
          return;
        } else if (response.statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        } else {
          throw Exception('Erreur lors de l\'acceptation: ${response.statusCode} - ${response.data}');
        }
      },
      maxRetries: 2,
      customErrorMessage: 'Impossible d\'accepter la mission',
    );
  }

  // Refuser une mission
  static Future<void> refuserMission(int missionId) async {
    return ErrorHandlerService.handleWithRetry(
      operation: () async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token == null) throw Exception('Token non trouvé');

        final dio = HttpClient.instance;
        final response = await dio.post(
          'http://192.168.11.243:8000/api/$basePath$missionId/refuser/',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );

        debugPrint('Réponse refuserMission ID $missionId: ${response.statusCode} - ${response.data}');
        if (response.statusCode == 200) {
          await CacheService.removeData(CacheKeys.missions);
          debugPrint('Cache missions vidé après refus');
          await fetchMissions(forceRefresh: true);
          return;
        } else if (response.statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        } else {
          throw Exception('Erreur lors du refus: ${response.statusCode} - ${response.data}');
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
        final response = await dio.post(
          'http://192.168.11.243:8000/api/$basePath$missionId/terminer/',
          data: body,
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );

        debugPrint('Réponse terminerMission ID $missionId: ${response.statusCode} - ${response.data}');
        if (response.statusCode == 200) {
          await CacheService.removeData(CacheKeys.missions);
          debugPrint('Cache missions vidé après terminaison');
          await fetchMissions(forceRefresh: true);
          return;
        } else if (response.statusCode == 401) {
          throw Exception('Session expirée. Veuillez vous reconnecter.');
        } else {
          throw Exception('Erreur lors de la finalisation: ${response.statusCode} - ${response.data}');
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
      'en_cours': 0,
      'refusees': 0,
      'terminees': 0,
    };

    for (final mission in missions) {
      final statut = mission['statut']?.toString().toLowerCase() ?? '';
      if (statut == 'terminée') {
        stats['terminees'] = (stats['terminees'] ?? 0) + 1;
      } else if (statut == 'acceptée') {
        stats['acceptees'] = (stats['acceptees'] ?? 0) + 1;
      } else if (statut == 'en cours') {
        stats['en_cours'] = (stats['en_cours'] ?? 0) + 1;
      } else if (statut == 'refusée') {
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
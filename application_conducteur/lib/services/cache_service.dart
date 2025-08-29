import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _cachePrefix = 'app_cache_';
  static const String _cacheTimestampPrefix = 'cache_timestamp_';
  static const Duration _defaultExpiration = Duration(minutes: 15);

  // Sauvegarder des données en cache
  static Future<void> setData(String key, dynamic data, {Duration? expiration}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix$key';
    final timestampKey = '$_cacheTimestampPrefix$key';
    
    final expirationTime = DateTime.now().add(expiration ?? _defaultExpiration);
    
    await prefs.setString(cacheKey, jsonEncode(data));
    await prefs.setString(timestampKey, expirationTime.toIso8601String());
  }

  // Récupérer des données du cache
  static Future<T?> getData<T>(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix$key';
    final timestampKey = '$_cacheTimestampPrefix$key';
    
    final cachedData = prefs.getString(cacheKey);
    final timestampString = prefs.getString(timestampKey);
    
    if (cachedData == null || timestampString == null) {
      return null;
    }
    
    try {
      final expirationTime = DateTime.parse(timestampString);
      if (DateTime.now().isAfter(expirationTime)) {
        // Cache expiré, supprimer
        await removeData(key);
        return null;
      }
      
      final data = jsonDecode(cachedData);
      return data as T;
    } catch (e) {
      // Erreur de parsing, supprimer le cache corrompu
      await removeData(key);
      return null;
    }
  }

  // Supprimer des données du cache
  static Future<void> removeData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix$key';
    final timestampKey = '$_cacheTimestampPrefix$key';
    
    await prefs.remove(cacheKey);
    await prefs.remove(timestampKey);
  }

  // Vider tout le cache
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_cachePrefix) || key.startsWith(_cacheTimestampPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  // Vérifier si des données sont en cache
  static Future<bool> hasData(String key) async {
    final data = await getData(key);
    return data != null;
  }

  // Obtenir la taille du cache
  static Future<int> getCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    int size = 0;
    
    for (final key in keys) {
      if (key.startsWith(_cachePrefix)) {
        final data = prefs.getString(key);
        if (data != null) {
          size += data.length;
        }
      }
    }
    
    return size;
  }

  // Nettoyer le cache expiré
  static Future<void> cleanExpiredCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final keysToRemove = <String>[];
    
    for (final key in keys) {
      if (key.startsWith(_cacheTimestampPrefix)) {
        final timestampString = prefs.getString(key);
        if (timestampString != null) {
          try {
            final expirationTime = DateTime.parse(timestampString);
            if (DateTime.now().isAfter(expirationTime)) {
              final dataKey = key.replaceFirst(_cacheTimestampPrefix, _cachePrefix);
              keysToRemove.add(key);
              keysToRemove.add(dataKey);
            }
          } catch (e) {
            // Timestamp invalide, supprimer
            keysToRemove.add(key);
          }
        }
      }
    }
    
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }

  // Cache avec gestion automatique
  static Future<T> getOrFetch<T>({
    required String key,
    required Future<T> Function() fetchFunction,
    Duration? expiration,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedData = await getData<T>(key);
      if (cachedData != null) {
        return cachedData;
      }
    }
    
    try {
      final data = await fetchFunction();
      await setData(key, data, expiration: expiration);
      return data;
    } catch (e) {
      // En cas d'erreur, essayer de récupérer du cache même expiré
      final cachedData = await getData<T>(key);
      if (cachedData != null) {
        return cachedData;
      }
      rethrow;
    }
  }

  // Cache pour les listes avec pagination
  static Future<List<T>> getOrFetchList<T>({
    required String key,
    required Future<List<T>> Function() fetchFunction,
    Duration? expiration,
    bool forceRefresh = false,
  }) async {
    return getOrFetch<List<T>>(
      key: key,
      fetchFunction: fetchFunction,
      expiration: expiration,
      forceRefresh: forceRefresh,
    );
  }

  // Cache pour les objets avec mise à jour conditionnelle
  static Future<T> getOrFetchWithCondition<T>({
    required String key,
    required Future<T> Function() fetchFunction,
    required bool Function(T cached, T fresh) shouldUpdate,
    Duration? expiration,
  }) async {
    final cachedData = await getData<T>(key);
    final freshData = await fetchFunction();
    
    if (cachedData == null || shouldUpdate(cachedData, freshData)) {
      await setData(key, freshData, expiration: expiration);
      return freshData;
    }
    
    return cachedData;
  }
}

// Clés de cache prédéfinies
class CacheKeys {
  static const String missions = 'missions';
  static const String vehicules = 'vehicules';
  static const String profil = 'profil';
  static const String alertes = 'alertes';
  static const String documents = 'documents';
  static const String historiques = 'historiques';
  static const String position = 'position';
  static const String settings = 'settings';
} 
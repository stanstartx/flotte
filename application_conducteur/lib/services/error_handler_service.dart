import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ErrorHandlerService {
  static const String _errorKey = 'last_error';
  static const String _retryCountKey = 'retry_count';
  
  // Types d'erreurs
  static const String networkError = 'NETWORK_ERROR';
  static const String authError = 'AUTH_ERROR';
  static const String serverError = 'SERVER_ERROR';
  static const String validationError = 'VALIDATION_ERROR';
  static const String unknownError = 'UNKNOWN_ERROR';

  // Messages d'erreur personnalisés
  static const Map<String, String> errorMessages = {
    networkError: 'Problème de connexion. Vérifiez votre connexion internet.',
    authError: 'Session expirée. Veuillez vous reconnecter.',
    serverError: 'Erreur serveur. Veuillez réessayer plus tard.',
    validationError: 'Données invalides. Vérifiez vos informations.',
    unknownError: 'Une erreur inattendue s\'est produite.',
  };

  // Gestion des erreurs avec retry automatique
  static Future<T> handleWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 2),
    String? customErrorMessage,
  }) async {
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        final errorType = _classifyError(e);
        final message = customErrorMessage ?? errorMessages[errorType] ?? errorMessages[unknownError]!;
        
        // Sauvegarder l'erreur
        await _saveError(errorType, message, e.toString());
        
        if (retryCount >= maxRetries) {
          throw Exception('$message (Tentative $retryCount/$maxRetries)');
        }
        
        // Attendre avant de réessayer
        await Future.delayed(delay * retryCount);
      }
    }
    
    throw Exception('Nombre maximum de tentatives atteint');
  }

  // Classification des erreurs
  static String _classifyError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return networkError;
    }
    
    if (errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('token')) {
      return authError;
    }
    
    if (errorString.contains('server') ||
        errorString.contains('500') ||
        errorString.contains('502')) {
      return serverError;
    }
    
    if (errorString.contains('validation') ||
        errorString.contains('invalid')) {
      return validationError;
    }
    
    return unknownError;
  }

  // Sauvegarder l'erreur
  static Future<void> _saveError(String type, String message, String details) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_errorKey, '$type|$message|$details');
    await prefs.setInt(_retryCountKey, (prefs.getInt(_retryCountKey) ?? 0) + 1);
  }

  // Récupérer la dernière erreur
  static Future<Map<String, String>?> getLastError() async {
    final prefs = await SharedPreferences.getInstance();
    final errorString = prefs.getString(_errorKey);
    if (errorString != null) {
      final parts = errorString.split('|');
      if (parts.length >= 3) {
        return {
          'type': parts[0],
          'message': parts[1],
          'details': parts[2],
        };
      }
    }
    return null;
  }

  // Effacer l'historique des erreurs
  static Future<void> clearErrorHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_errorKey);
    await prefs.remove(_retryCountKey);
  }

  // Afficher un SnackBar d'erreur
  static void showErrorSnackBar(BuildContext context, String message, {
    Duration duration = const Duration(seconds: 4),
    Color backgroundColor = Colors.red,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // Afficher une boîte de dialogue d'erreur
  static Future<void> showErrorDialog(BuildContext context, String title, String message) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Vérifier la connectivité
  static Future<bool> checkConnectivity() async {
    try {
      // Test simple de connectivité
      final response = await Future.any([
        Future.delayed(const Duration(seconds: 3), () => throw TimeoutException()),
        // Ici vous pourriez ajouter un vrai test de connectivité
      ]);
      return true;
    } catch (e) {
      return false;
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException([this.message = 'Timeout']);
  
  @override
  String toString() => message;
} 
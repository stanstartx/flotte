import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static const String _notificationsKey = 'notifications';
  static const String _settingsKey = 'notification_settings';
  
  // Types de notifications
  static const String missionNotification = 'MISSION';
  static const String alertNotification = 'ALERT';
  static const String systemNotification = 'SYSTEM';
  static const String maintenanceNotification = 'MAINTENANCE';

  // Paramètres par défaut
  static const Map<String, bool> defaultSettings = {
    'missions': true,
    'alerts': true,
    'system': true,
    'maintenance': true,
    'sound': true,
    'vibration': true,
    'auto_dismiss': false,
  };

  // Ajouter une notification
  static Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    String? action,
    Map<String, dynamic>? data,
    bool isRead = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    
    final notification = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'message': message,
      'type': type,
      'action': action,
      'data': data,
      'isRead': isRead,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    notifications.insert(0, notification);
    
    // Garder seulement les 50 dernières notifications
    if (notifications.length > 50) {
      notifications.removeRange(50, notifications.length);
    }
    
    await prefs.setString(_notificationsKey, jsonEncode(notifications));
    
    // Afficher une notification toast si l'application est ouverte
    _showToastNotification(title, message, type);
  }

  // Récupérer toutes les notifications
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsString = prefs.getString(_notificationsKey);
    
    if (notificationsString != null) {
      try {
        final List<dynamic> data = jsonDecode(notificationsString);
        return List<Map<String, dynamic>>.from(data);
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  // Marquer une notification comme lue
  static Future<void> markAsRead(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    
    for (int i = 0; i < notifications.length; i++) {
      if (notifications[i]['id'] == notificationId) {
        notifications[i]['isRead'] = true;
        break;
      }
    }
    
    await prefs.setString(_notificationsKey, jsonEncode(notifications));
  }

  // Marquer toutes les notifications comme lues
  static Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    
    for (final notification in notifications) {
      notification['isRead'] = true;
    }
    
    await prefs.setString(_notificationsKey, jsonEncode(notifications));
  }

  // Supprimer une notification
  static Future<void> deleteNotification(String notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getNotifications();
    
    notifications.removeWhere((notification) => notification['id'] == notificationId);
    
    await prefs.setString(_notificationsKey, jsonEncode(notifications));
  }

  // Supprimer toutes les notifications
  static Future<void> clearAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notificationsKey);
  }

  // Obtenir le nombre de notifications non lues
  static Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((notification) => !notification['isRead']).length;
  }

  // Obtenir les paramètres de notification
  static Future<Map<String, bool>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString(_settingsKey);
    
    if (settingsString != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(settingsString);
        return Map<String, bool>.from(data);
      } catch (e) {
        return Map<String, bool>.from(defaultSettings);
      }
    }
    
    return Map<String, bool>.from(defaultSettings);
  }

  // Mettre à jour les paramètres de notification
  static Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }

  // Notifications spécifiques
  static Future<void> notifyNewMission(String missionTitle) async {
    final settings = await getNotificationSettings();
    if (settings['missions'] == true) {
      await addNotification(
        title: 'Nouvelle Mission',
        message: 'Vous avez une nouvelle mission: $missionTitle',
        type: missionNotification,
        action: 'OPEN_MISSION',
      );
    }
  }

  static Future<void> notifyMissionAccepted(String missionTitle) async {
    await addNotification(
      title: 'Mission Acceptée',
      message: 'Mission acceptée: $missionTitle',
      type: missionNotification,
    );
  }

  static Future<void> notifyMissionCompleted(String missionTitle) async {
    await addNotification(
      title: 'Mission Terminée',
      message: 'Mission terminée avec succès: $missionTitle',
      type: missionNotification,
    );
  }

  static Future<void> notifyMaintenance(String vehicleInfo) async {
    final settings = await getNotificationSettings();
    if (settings['maintenance'] == true) {
      await addNotification(
        title: 'Entretien Requis',
        message: 'Entretien prévu pour: $vehicleInfo',
        type: maintenanceNotification,
        action: 'OPEN_MAINTENANCE',
      );
    }
  }

  static Future<void> notifyAlert(String alertMessage) async {
    final settings = await getNotificationSettings();
    if (settings['alerts'] == true) {
      await addNotification(
        title: 'Alerte',
        message: alertMessage,
        type: alertNotification,
        action: 'OPEN_ALERT',
      );
    }
  }

  static Future<void> notifySystem(String message) async {
    final settings = await getNotificationSettings();
    if (settings['system'] == true) {
      await addNotification(
        title: 'Système',
        message: message,
        type: systemNotification,
      );
    }
  }

  // Afficher une notification toast
  static void _showToastNotification(String title, String message, String type) {
    // Cette méthode sera appelée quand l'application est ouverte
    // Vous pouvez l'implémenter avec un SnackBar ou une notification toast
  }

  // Obtenir la couleur selon le type de notification
  static Color getNotificationColor(String type) {
    switch (type) {
      case missionNotification:
        return Colors.blue;
      case alertNotification:
        return Colors.red;
      case maintenanceNotification:
        return Colors.orange;
      case systemNotification:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Obtenir l'icône selon le type de notification
  static IconData getNotificationIcon(String type) {
    switch (type) {
      case missionNotification:
        return Icons.assignment;
      case alertNotification:
        return Icons.warning;
      case maintenanceNotification:
        return Icons.build;
      case systemNotification:
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  // Filtrer les notifications par type
  static Future<List<Map<String, dynamic>>> getNotificationsByType(String type) async {
    final notifications = await getNotifications();
    return notifications.where((notification) => notification['type'] == type).toList();
  }

  // Obtenir les notifications récentes (dernières 24h)
  static Future<List<Map<String, dynamic>>> getRecentNotifications() async {
    final notifications = await getNotifications();
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    return notifications.where((notification) {
      final timestamp = DateTime.parse(notification['timestamp']);
      return timestamp.isAfter(yesterday);
    }).toList();
  }
} 
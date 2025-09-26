class AppConfig {
  // ============================
  // Configuration Google Maps
  // ============================
  static const String googleMapsApiKey =
      'AIzaSyCyze4WaCmpwGGOB2GkpwH-pTNc04DrEKQ';

  // ============================
  // Configuration API Backend
  // ============================
  // Utilisez l'IP de votre machine si vous testez sur un appareil physique
  static const String apiBaseUrl = 'http://192.168.11.243:8000/api';
  // Pour l'émulateur Android : 'http://10.0.2.2:8000/api'
  // Pour localhost : 'http://127.0.0.1:8000/api'

  // ============================
  // Configuration Application
  // ============================
  static const String appName = 'Application Conducteur';
  static const String appVersion = '1.0.0';

  // ============================
  // Authentification
  // ============================
  // Ce token sera mis à jour dynamiquement après login
  static String token = "";

  // ============================
  // Coordonnées par défaut (Abidjan)
  // ============================
  static const double defaultLatitude = 5.3600;
  static const double defaultLongitude = -4.0083;
  static const double defaultZoom = 12.0;
}

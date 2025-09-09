# Intégration Google Maps - Application de Gestion de Flotte

## Vue d'ensemble

L'API Google Maps a été intégrée avec succès dans les applications Flutter de gestion de flotte automobile. Cette intégration permet d'afficher des cartes interactives dans les pages trajets des applications conducteur et admin.

## Clé API utilisée

```
AIzaSyCyze4WaCmpwGGOB2GkpwH-pTNc04DrEKQ
```

## Configuration effectuée

### 1. Application Conducteur (`application_conducteur`)

#### Fichiers modifiés :
- `android/app/src/main/AndroidManifest.xml` - Ajout de la clé API Google Maps
- `ios/Runner/AppDelegate.swift` - Configuration iOS avec import GoogleMaps
- `web/index.html` - Script Google Maps pour le web
- `lib/config.dart` - Fichier de configuration centralisé
- `lib/ecrans/trajets.dart` - Intégration de la carte interactive

#### Fonctionnalités ajoutées :
- Carte interactive Google Maps dans la modal de détails des trajets
- Marqueurs pour les points de départ et d'arrivée
- Ligne de trajet entre les points
- Gestion d'erreur avec fallback visuel

### 2. Application Admin (`flotte`)

#### Fichiers modifiés :
- `lib/config.dart` - Fichier de configuration centralisé
- `lib/ecrans/admin/trajets_modern.dart` - Mise à jour pour utiliser la configuration centralisée

#### Fonctionnalités existantes améliorées :
- Utilisation de la configuration centralisée
- Coordonnées par défaut mises à jour pour Abidjan
- URLs d'API centralisées

## Structure des fichiers de configuration

### `lib/config.dart`
```dart
class AppConfig {
  // Configuration Google Maps
  static const String googleMapsApiKey = 'AIzaSyCyze4WaCmpwGGOB2GkpwH-pTNc04DrEKQ';
  
  // Configuration API Backend
  static const String baseUrl = 'http://localhost:8000'; // ou 'http://192.168.11.243:8000'
  
  // Coordonnées par défaut (Abidjan)
  static const double defaultLatitude = 5.3600;
  static const double defaultLongitude = -4.0083;
  static const double defaultZoom = 12.0;
}
```

## Fonctionnalités des cartes

### Application Conducteur
- **Carte statique** : Image Google Maps avec marqueurs pour les trajets
- **Carte interactive** : Google Maps Flutter avec marqueurs et polylines
- **Gestion d'erreur** : Affichage d'un placeholder en cas d'échec de chargement

### Application Admin
- **Suivi en temps réel** : Affichage des conducteurs et de leurs positions
- **Trajets historiques** : Visualisation des trajets passés
- **Marqueurs dynamiques** : Différents marqueurs selon le statut des conducteurs
- **Polylines** : Lignes de trajet entre les points

## Dépendances requises

### Dans `pubspec.yaml`
```yaml
dependencies:
  google_maps_flutter: ^2.5.0  # ou version plus récente
  google_fonts: ^6.1.0
  http: ^1.4.0
  shared_preferences: ^2.5.3
```

## Configuration par plateforme

### Android
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyCyze4WaCmpwGGOB2GkpwH-pTNc04DrEKQ" />
```

### iOS
```swift
import GoogleMaps

// Dans AppDelegate.swift
GMSServices.provideAPIKey("AIzaSyCyze4WaCmpwGGOB2GkpwH-pTNc04DrEKQ")
```

### Web
```html
<script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyCyze4WaCmpwGGOB2GkpwH-pTNc04DrEKQ&libraries=places"></script>
```

## Utilisation

### Affichage d'une carte simple
```dart
GoogleMap(
  initialCameraPosition: CameraPosition(
    target: LatLng(AppConfig.defaultLatitude, AppConfig.defaultLongitude),
    zoom: AppConfig.defaultZoom,
  ),
  markers: markers,
  polylines: polylines,
)
```

### Création de marqueurs
```dart
Marker(
  markerId: MarkerId('depart'),
  position: LatLng(latitude, longitude),
  infoWindow: InfoWindow(
    title: 'Départ',
    snippet: 'Point de départ du trajet',
  ),
  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
)
```

## Notes importantes

1. **Sécurité** : La clé API est exposée dans le code client. Pour la production, considérez l'utilisation de restrictions d'API dans la console Google Cloud.

2. **Coordonnées** : Les coordonnées actuelles sont fictives et basées sur Abidjan. Pour une utilisation réelle, intégrez un service de géocodage.

3. **Performance** : Les cartes sont optimisées pour les performances avec des contrôles de zoom et de localisation désactivés dans certains contextes.

4. **Maintenance** : Toute modification de la clé API doit être effectuée dans le fichier `config.dart` et dans les fichiers de configuration des plateformes.

## Prochaines étapes recommandées

1. **Géocodage** : Intégrer un service de géocodage pour convertir les adresses en coordonnées
2. **Directions API** : Utiliser l'API Directions pour des trajets plus précis
3. **Clustering** : Implémenter le clustering de marqueurs pour de meilleures performances
4. **Offline** : Considérer le cache des tuiles pour une utilisation hors ligne
5. **Sécurité** : Mettre en place des restrictions d'API dans Google Cloud Console

## Support

Pour toute question ou problème lié à l'intégration Google Maps, consultez :
- [Documentation Google Maps Flutter](https://pub.dev/packages/google_maps_flutter)
- [Google Maps Platform](https://developers.google.com/maps)
- [Console Google Cloud](https://console.cloud.google.com/)



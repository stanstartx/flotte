# Fonctionnalités Temps Réel - Page Trajets Admin

## Vue d'ensemble

La page trajets admin a été améliorée pour afficher les vraies données en temps réel des conducteurs et de leurs positions. Cette mise à jour permet un suivi en direct de la flotte avec des statistiques actualisées automatiquement.

## Nouvelles APIs Backend

### 1. API Positions des Conducteurs
**Endpoint:** `GET /api/drivers/positions/`

**Description:** Récupère les dernières positions de tous les conducteurs avec leurs informations.

**Réponse:**
```json
[
  {
    "id": 1,
    "username": "conducteur1",
    "first_name": "Jean",
    "last_name": "Dupont",
    "is_online": true,
    "last_position": {
      "latitude": 5.3600,
      "longitude": -4.0083,
      "timestamp": "2025-01-18T10:30:00Z"
    }
  }
]
```

### 2. API Historique des Trajets
**Endpoint:** `GET /api/drivers/{driver_id}/trips/`

**Description:** Récupère l'historique des trajets d'un conducteur spécifique.

**Réponse:**
```json
[
  {
    "id": 1,
    "raison": "Livraison",
    "lieu_depart": "Abidjan Plateau",
    "lieu_arrivee": "Yopougon",
    "date_depart": "2025-01-18T08:00:00Z",
    "date_arrivee": "2025-01-18T10:00:00Z",
    "statut": "terminee",
    "distance_km": 15.5,
    "depart_latitude": 5.3600,
    "depart_longitude": -4.0083,
    "arrivee_latitude": 5.3700,
    "arrivee_longitude": -4.0100
  }
]
```

## Fonctionnalités Implémentées

### 1. Suivi en Temps Réel
- **Actualisation automatique** : Les données se mettent à jour toutes les 30 secondes
- **Statut en ligne** : Un conducteur est considéré en ligne si sa dernière position date de moins de 5 minutes
- **Positions réelles** : Affichage des vraies coordonnées GPS des conducteurs

### 2. Carte Interactive
- **Marqueurs dynamiques** : 
  - 🟢 Vert pour les conducteurs en ligne
  - 🔴 Rouge pour les conducteurs hors ligne
- **Informations détaillées** : Clic sur un marqueur pour voir les infos du conducteur
- **Sélection interactive** : Clic sur un conducteur pour voir ses trajets

### 3. Historique des Trajets
- **Affichage des trajets** : Liste des trajets du conducteur sélectionné
- **Coordonnées réelles** : Utilisation des vraies coordonnées GPS si disponibles
- **Fallback intelligent** : Coordonnées fictives si les vraies ne sont pas disponibles
- **Visualisation sur carte** : Marqueurs de départ (bleu) et d'arrivée (rouge)

### 4. Statistiques en Temps Réel
- **Total conducteurs** : Nombre total de conducteurs dans la flotte
- **Conducteurs en ligne** : Nombre de conducteurs actuellement connectés
- **Mise à jour automatique** : Les statistiques se mettent à jour avec les données

## Interface Utilisateur

### Panneau Gauche - Liste des Conducteurs
- **Nom complet** : Affichage du prénom et nom si disponibles
- **Statut visuel** : Indicateur de couleur (vert/gris) pour le statut en ligne
- **Dernière position** : Timestamp de la dernière position reçue
- **Sélection** : Mise en surbrillance du conducteur sélectionné

### Panneau Central - Carte
- **Vue d'ensemble** : Tous les conducteurs visibles sur la carte
- **Zoom et navigation** : Contrôles de carte standard
- **Marqueurs interactifs** : Clic pour sélectionner un conducteur
- **Trajets affichés** : Lignes de trajet pour le conducteur sélectionné

### Panneau Droit - Statistiques et Trajets
- **Cartes statistiques** : Total et conducteurs en ligne
- **Graphique de répartition** : Barres de progression pour les statuts
- **Liste des trajets** : Historique du conducteur sélectionné

## Gestion des Données

### Actualisation Automatique
```dart
void _startAutoRefresh() {
  _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
    if (mounted) {
      loadData();
    }
  });
}
```

### Gestion des Coordonnées
- **Vraies coordonnées** : Utilisation des champs `depart_latitude`, `depart_longitude`, etc.
- **Fallback** : Coordonnées fictives basées sur Abidjan si les vraies ne sont pas disponibles
- **Validation** : Vérification de la présence des coordonnées avant affichage

### Gestion des Erreurs
- **Connexion** : Gestion des erreurs de réseau
- **Données manquantes** : Affichage de messages d'erreur appropriés
- **Fallback** : Affichage de données par défaut en cas d'erreur

## Configuration

### Timer d'Actualisation
```dart
// Actualisation toutes les 30 secondes
Timer.periodic(const Duration(seconds: 30), (timer) {
  loadData();
});
```

### Seuil de Connexion
```python
# Un conducteur est en ligne si sa dernière position date de moins de 5 minutes
time_diff = timezone.now() - last_position.timestamp
is_online = time_diff.total_seconds() < 300  # 5 minutes
```

## Utilisation

### 1. Visualisation Générale
- Ouvrir la page trajets admin
- Voir tous les conducteurs sur la carte
- Consulter les statistiques en temps réel

### 2. Suivi d'un Conducteur
- Cliquer sur un conducteur dans la liste de gauche
- Voir sa position sur la carte
- Consulter son historique de trajets

### 3. Visualisation des Trajets
- Sélectionner un conducteur
- Voir ses trajets affichés sur la carte
- Cliquer sur un trajet pour centrer la carte dessus

## Avantages

1. **Suivi en temps réel** : Visibilité immédiate de l'état de la flotte
2. **Données précises** : Utilisation des vraies positions GPS
3. **Interface intuitive** : Navigation facile entre conducteurs et trajets
4. **Performance optimisée** : Actualisation automatique sans rechargement manuel
5. **Robustesse** : Gestion des erreurs et fallbacks appropriés

## Prochaines Améliorations

1. **Géocodage** : Conversion automatique des adresses en coordonnées
2. **Directions API** : Calcul de trajets optimisés
3. **Notifications** : Alertes en cas de problème avec un conducteur
4. **Export** : Possibilité d'exporter les données de trajets
5. **Filtres** : Filtrage par date, statut, ou zone géographique

## Support Technique

Pour toute question ou problème :
- Vérifier la connexion réseau
- S'assurer que l'API backend est accessible
- Contrôler les permissions d'authentification
- Vérifier la configuration Google Maps



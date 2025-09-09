# Flotte

Application de gestion de flotte automobile pour le Groupe Laroche.

## Description
Gestion complète des véhicules, missions, conducteurs et alertes en temps réel. Monorepo incluant :
- Application admin Flutter (tableau de bord, utilisateurs, véhicules, trajets).
- Application conducteur Flutter (connexion, dashboard, incidents, statistiques, paramètres).
- Backend Django (API pour auth, missions, historiques, intégration Google Maps).

## Installation et Lancement

### Backend (Django)
1. Naviguez vers le dossier backend : `cd flotte-backend`
2. Installez les dépendances : `pip install -r requirements.txt` (créez-le si absent avec vos paquets comme django, djangorestframework, etc.)
3. Appliquez les migrations : `python manage.py migrate`
4. Créez un superutilisateur : `python manage.py createsuperuser`
5. Lancez le serveur : `python manage.py runserver` (accessible sur http://127.0.0.1:8000 ou http://192.168.11.243:8000 pour ton setup réseau)

### Frontend (Flutter - Admin ou Conducteur)
1. Naviguez vers le dossier : `cd flotte` (pour admin) ou `cd application_conducteur` (pour conducteur)
2. Récupérez les dépendances : `flutter pub get`
3. Lancez en mode web : `flutter run -d chrome`
4. Ou sur mobile : `flutter run` (avec émulateur Android/iOS connecté)

## Configuration
- **URL API de base** : Modifiez dans `lib/config.dart` (ex. : `const String baseUrl = 'http://localhost:8000';` pour dev, ou 'http://192.168.11.243:8000' pour prod/test).
- **CORS** : Configurez dans `flotte-backend/core/settings.py` (ajoutez `CORS_ALLOWED_ORIGINS = ['http://localhost:3000', 'http://127.0.0.1:8080']` ou domaines Flutter web).
- **Google Maps** : Ajoutez votre clé API dans les fichiers config (voir `flotte-backend/INTEGRATION_GOOGLE_MAPS.md` pour setup).
- **Temps réel** : Suivi des trajets et alertes (voir `flotte-backend/FONCTIONNALITES_TEMPS_REEL.md`).
- **Environnements** : Utilisez un fichier `.env` pour les secrets (API keys, DB passwords) – ignoré par Git via `.gitignore`.
- **Base de données** : SQLite par défaut (dev) ; passez à PostgreSQL/MySQL en prod via `settings.py`.

## Fonctionnalités Principales
- **Admin** : Gestion des missions, véhicules, utilisateurs, historiques, statistiques.
- **Conducteur** : Connexion sécurisée, alertes, dashboard, upload documents, rapports incidents.
- **Backend** : Auth JWT, serializers, views pour CRUD, URLs API (ex. : /api/missions/, /api/trajets/).
- **Intégrations** : Google Maps pour trajets, temps réel via WebSockets (si implémenté).

## Développement et Tests
- **Branche principale** : `main`.
- **Tests Flutter** : `flutter test` (dans chaque dossier app).
- **Tests Django** : `python manage.py test`.
- **Hot Reload** : Utilisez `flutter run --hot` pour dev rapide.
- **Débogage Web** : `flutter run -d chrome --profile` si bugs DebugService (fixé après upgrade Flutter).
- **Dépendances** : Vérifiez `pubspec.yaml` (Flutter) et `requirements.txt` (Django).

## Contribuer
1. Fork le repo.
2. Créez une branche : `git checkout -b feature/nouvelle-fonction`.
3. Committez : `git commit -m "Ajout de la fonctionnalité X"`.
4. Poussez : `git push origin feature/nouvelle-fonction`.
5. Ouvrez une Pull Request vers `main`.

## Licence
Interne au Groupe Laroche (propriété privée). Voir `LICENSE` pour détails.

## Contact
Stanislas N'drin – stanislasndrin@GroupeLaroche.local

---

*Projet mis à jour en septembre 2025. Pour support, contactez l'équipe dev.*
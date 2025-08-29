# Gestion de Flotte - Application de Suivi de Véhicules

## Architecture du Projet

Le projet est composé de deux parties principales :

### Backend (Django REST Framework)
- **Technologies** : Python, Django, Django REST Framework, SQLite
- **Structure** :
  - `core/` : Configuration principale de Django
  - `fleet/` : Application principale de gestion de flotte
  - `db.sqlite3` : Base de données SQLite

### Frontend (Flutter)
- **Technologies** : Dart, Flutter
- **Structure** :
  - `lib/`
    - `config/` : Configuration de l'application
    - `ecrans/` : Écrans de l'application
    - `modeles/` : Modèles de données
    - `providers/` : Gestion d'état (Provider)
    - `services/` : Services (API, navigation, etc.)
    - `widgets/` : Composants réutilisables

## Configuration

### Backend

1. **Environnement Python**
   ```bash
   python -m venv env
   source env/bin/activate  # Linux/Mac
   # ou
   .\env\Scripts\activate  # Windows
   ```

2. **Installation des dépendances**
   ```bash
   pip install -r requirements.txt
   ```

3. **Base de données**
   ```bash
   python manage.py migrate
   ```

4. **Lancer le serveur**
   ```bash
   python manage.py runserver
   ```

### Frontend

1. **Installation de Flutter**
   - Suivre les instructions sur [flutter.dev](https://flutter.dev/docs/get-started/install)

2. **Dépendances Flutter**
   ```bash
   cd gestion_flotte
   flutter pub get
   ```

3. **Lancer l'application**
   ```bash
   flutter run -d chrome  # Pour le web
   # ou
   flutter run  # Pour mobile/desktop
   ```

## Fonctionnalités

### Backend (API REST)
- Authentification JWT
- Gestion des véhicules
- Suivi des maintenances
- Gestion des conducteurs
- Génération de rapports

### Frontend
- Interface de connexion
- Tableau de bord
- Gestion des véhicules
- Suivi des maintenances
- Gestion des conducteurs
- Rapports et statistiques

## Configuration de l'Environnement

### Backend
- `SECRET_KEY` : Clé secrète Django
- `DEBUG` : Mode développement/production
- `ALLOWED_HOSTS` : Hôtes autorisés
- `DATABASES` : Configuration de la base de données

### Frontend
- `Config` : Classe de configuration avec les URLs de l'API
- `API_URL` : URL du backend
- `API_KEY` : Clé d'API (si nécessaire)

## Sécurité
- Authentification JWT
- CORS configuré
- Validation des données
- Protection CSRF

## Développement

### Backend
1. Créer une branche pour votre fonctionnalité
2. Implémenter les modèles et les vues
3. Ajouter les tests
4. Créer une pull request

### Frontend
1. Créer une branche pour votre fonctionnalité
2. Implémenter l'interface utilisateur
3. Connecter avec l'API
4. Créer une pull request

## Déploiement

### Backend
1. Configurer les variables d'environnement
2. Migrer la base de données
3. Collecter les fichiers statiques
4. Configurer le serveur web (Nginx/Apache)

### Frontend
1. Construire l'application
   ```bash
   flutter build web  # Pour le web
   # ou
   flutter build apk  # Pour Android
   # ou
   flutter build ios  # Pour iOS
   ```
2. Déployer sur le serveur web

## Support

Pour toute question ou problème :
1. Consulter la documentation
2. Ouvrir une issue sur GitHub
3. Contacter l'équipe de développement
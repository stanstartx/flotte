# 🚀 GUIDE DE LANCEMENT - PROJET GESTION DE FLOTTE

## 📋 PRÉREQUIS

- **Python 3.12+** ✅ (installé)
- **Flutter 3.32+** ✅ (installé)
- **Git** ✅ (installé)

## 🎯 LANCEMENT RAPIDE

### Option 1 : Scripts automatiques (Recommandé)

```bash
# 1. Lancer le guide
./start_all.sh

# 2. Ouvrir 3 terminaux et exécuter :
# Terminal 1 - Backend
./start_backend.sh

# Terminal 2 - Application principale
./start_flutter_main.sh

# Terminal 3 - Application conducteur
./start_flutter_conducteur.sh
```

### Option 2 : Commandes manuelles

## 🔧 LANCEMENT MANUEL DÉTAILLÉ

### 1. BACKEND DJANGO

```bash
# Aller dans le dossier backend
cd flotte-backend

# Créer et activer l'environnement virtuel
python3 -m venv venv
source venv/bin/activate

# Installer les dépendances
python -m pip install -r requirements.txt

# Appliquer les migrations
python manage.py migrate

# Créer un superutilisateur (optionnel)
python manage.py createsuperuser

# Lancer le serveur
python manage.py runserver 0.0.0.0:8000
```

**✅ Backend accessible sur :** `http://localhost:8000`

### 2. APPLICATION FLUTTER PRINCIPALE

```bash
# Aller dans le dossier flotte
cd flotte

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run -d chrome --web-port 3000
```

**✅ Application accessible sur :** `http://localhost:3000`

### 3. APPLICATION CONDUCTEUR

```bash
# Aller dans le dossier application_conducteur
cd application_conducteur

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run -d chrome --web-port 3001
```

**✅ Application conducteur accessible sur :** `http://localhost:3001`

## 🔑 IDENTIFIANTS DE TEST

### Créer des utilisateurs de test :

```bash
# Dans le dossier flotte-backend avec l'environnement virtuel activé
python manage.py shell

# Dans le shell Python :
from django.contrib.auth.models import User
from fleet.models import UserProfile, Driver

# Créer un admin
admin_user = User.objects.create_user('admin', 'admin@test.com', 'admin123')
admin_user.is_staff = True
admin_user.is_superuser = True
admin_user.save()
admin_profile = UserProfile.objects.get(user=admin_user)
admin_profile.role = 'admin'
admin_profile.save()

# Créer un gestionnaire
gest_user = User.objects.create_user('gestionnaire', 'gest@test.com', 'gestion123')
gest_profile = UserProfile.objects.get(user=gest_user)
gest_profile.role = 'gestionnaire'
gest_profile.save()

# Créer un conducteur
cond_user = User.objects.create_user('conducteur', 'cond@test.com', 'conducteur123')
cond_profile = UserProfile.objects.get(user=cond_user)
cond_profile.role = 'conducteur'
cond_profile.save()
driver = Driver.objects.create(
    user_profile=cond_profile,
    numero_permis='B123456789',
    permis='B'
)
```

### Identifiants de connexion :

| Rôle | Utilisateur | Mot de passe |
|------|-------------|--------------|
| Admin | `admin` | `admin123` |
| Gestionnaire | `gestionnaire` | `gestion123` |
| Conducteur | `conducteur` | `conducteur123` |

## 🌐 URLs D'ACCÈS

- **Backend API** : `http://localhost:8000`
- **Admin Django** : `http://localhost:8000/admin`
- **Application Admin/Gestionnaire** : `http://localhost:3000`
- **Application Conducteur** : `http://localhost:3001`

## 🔍 VÉRIFICATION DU FONCTIONNEMENT

### 1. Vérifier le backend
```bash
curl http://localhost:8000/api/vehicles/
```

### 2. Vérifier les applications Flutter
- Ouvrir `http://localhost:3000` dans le navigateur
- Ouvrir `http://localhost:3001` dans le navigateur

## 🛠️ DÉPANNAGE

### Problème de port déjà utilisé
```bash
# Vérifier les ports utilisés
netstat -tulpn | grep :8000
netstat -tulpn | grep :3000
netstat -tulpn | grep :3001

# Tuer le processus si nécessaire
kill -9 <PID>
```

### Problème de dépendances Flutter
```bash
flutter clean
flutter pub get
```

### Problème de migrations Django
```bash
python manage.py makemigrations
python manage.py migrate
```

## 📱 FONCTIONNALITÉS DISPONIBLES

### Application Admin/Gestionnaire (`http://localhost:3000`)
- ✅ Tableau de bord
- ✅ Gestion des véhicules
- ✅ Gestion des conducteurs
- ✅ Gestion des missions
- ✅ Suivi des trajets
- ✅ Alertes et notifications
- ✅ Documents et rapports
- ✅ Statistiques

### Application Conducteur (`http://localhost:3001`)
- ✅ Tableau de bord conducteur
- ✅ Missions assignées
- ✅ Véhicules affectés
- ✅ Documents
- ✅ Alertes
- ✅ Profil utilisateur

## 🎉 SUCCÈS !

Si tout fonctionne, vous devriez voir :
- ✅ Backend Django en cours d'exécution sur le port 8000
- ✅ Application principale Flutter sur le port 3000
- ✅ Application conducteur Flutter sur le port 3001
- ✅ Possibilité de se connecter avec les identifiants de test 
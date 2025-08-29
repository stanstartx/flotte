# 🚀 COMMANDES DE LANCEMENT - PROJET GESTION DE FLOTTE

## 📋 RÉSUMÉ RAPIDE

**3 applications à lancer dans 3 terminaux différents :**

1. **Backend Django** (Port 8000)
2. **Application Flutter Principale** (Port 3000) 
3. **Application Conducteur** (Port 3001)

---

## 🎯 COMMANDES COMPLÈTES

### **TERMINAL 1 - BACKEND DJANGO**

```bash
# Aller dans le dossier backend
cd flotte-backend

# Créer l'environnement virtuel (si pas déjà fait)
python3 -m venv venv

# Activer l'environnement virtuel
source venv/bin/activate

# Installer les dépendances
python -m pip install -r requirements.txt

# Appliquer les migrations
python manage.py migrate

# Lancer le serveur
python manage.py runserver 0.0.0.0:8000
```

**✅ Résultat :** Backend accessible sur `http://localhost:8000`

---

### **TERMINAL 2 - APPLICATION PRINCIPALE**

```bash
# Aller dans le dossier flotte
cd flotte

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run -d chrome --web-port 3000
```

**✅ Résultat :** Application accessible sur `http://localhost:3000`

---

### **TERMINAL 3 - APPLICATION CONDUCTEUR**

```bash
# Aller dans le dossier application_conducteur
cd application_conducteur

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run -d chrome --web-port 3001
```

**✅ Résultat :** Application accessible sur `http://localhost:3001`

---

## 🔧 SCRIPTS AUTOMATIQUES

### **Option 1 : Scripts individuels**

```bash
# Terminal 1
./start_backend.sh

# Terminal 2  
./start_flutter_main.sh

# Terminal 3
./start_flutter_conducteur.sh
```

### **Option 2 : Guide complet**

```bash
./start_all.sh
```

### **Option 3 : Test d'installation**

```bash
./test_installation.sh
```

---

## 🔑 CRÉATION DES UTILISATEURS DE TEST

```bash
# Dans le dossier flotte-backend avec l'environnement virtuel activé
cd flotte-backend
source venv/bin/activate

# Ouvrir le shell Django
python manage.py shell

# Dans le shell Python, exécuter :
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

---

## 🌐 URLs D'ACCÈS

| Service | URL | Description |
|---------|-----|-------------|
| Backend API | `http://localhost:8000` | API Django REST |
| Admin Django | `http://localhost:8000/admin` | Interface d'administration |
| App Principale | `http://localhost:3000` | Admin/Gestionnaire |
| App Conducteur | `http://localhost:3001` | Interface conducteur |

---

## 🔍 VÉRIFICATION

### **Test du backend**
```bash
curl http://localhost:8000/api/vehicles/
```

### **Test des applications**
- Ouvrir `http://localhost:3000` dans le navigateur
- Ouvrir `http://localhost:3001` dans le navigateur

---

## 🛠️ DÉPANNAGE

### **Port déjà utilisé**
```bash
# Vérifier
netstat -tulpn | grep :8000
netstat -tulpn | grep :3000
netstat -tulpn | grep :3001

# Tuer le processus
kill -9 <PID>
```

### **Erreur de dépendances Flutter**
```bash
flutter clean
flutter pub get
```

### **Erreur de migrations Django**
```bash
python manage.py makemigrations
python manage.py migrate
```

---

## 🎉 SUCCÈS !

Si tout fonctionne, vous devriez voir :
- ✅ Backend Django sur `http://localhost:8000`
- ✅ Application principale sur `http://localhost:3000`
- ✅ Application conducteur sur `http://localhost:3001`
- ✅ Possibilité de se connecter avec les identifiants de test

**Identifiants de test :**
- Admin : `admin` / `admin123`
- Gestionnaire : `gestionnaire` / `gestion123`
- Conducteur : `conducteur` / `conducteur123` 
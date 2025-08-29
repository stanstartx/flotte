# Guide de Déploiement - Flotte Auto

## Plan des ports
- **API Django** → http://192.168.11.243:8080
- **Admin (Flutter Web)** → http://192.168.11.243:8081
- **Mobile (Flutter Web)** → http://192.168.11.243:8082

## Étape 0 - Préparation des fichiers

### Sur votre machine de développement :
1. Exécutez le script de build Flutter :
   ```powershell
   .\build_flutter_apps.ps1
   ```

2. Copiez les fichiers vers le serveur :
   - `flotte-backend/` → `C:\Sites\api\current\`
   - `flotte/build/web/*` → `C:\Sites\admin\current\`
   - `application_conducteur/build/web/*` → `C:\Sites\mobile\current\`

## Étape 1 - Configuration du serveur

### Prérequis (à installer une seule fois) :
- IIS (déjà présent)
- URL Rewrite 2.1
- Application Request Routing (ARR)
- Python 3.x
- NSSM (pour les services Windows)

### Pare-feu Windows :
Autoriser les ports 8080, 8081, 8082 (TCP)

## Étape 2 - Configuration Django

### Sur le serveur, dans `C:\Sites\api\current\` :

1. Créer l'environnement virtuel :
   ```powershell
   python -m venv venv
   .\venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. Appliquer les migrations :
   ```powershell
   python manage.py migrate
   python manage.py collectstatic --noinput
   ```

3. Tester le serveur :
   ```powershell
   waitress-serve --listen=127.0.0.1:8000 core.wsgi:application
   ```

## Étape 3 - Créer le service Windows Django

### Avec NSSM :
```powershell
C:\Tools\nssm\nssm.exe install django_api
```

**Configuration NSSM :**
- Application Path : `C:\Sites\api\current\venv\Scripts\waitress-serve.exe`
- Startup directory : `C:\Sites\api\current`
- Arguments : `--listen=127.0.0.1:8000 core.wsgi:application`
- Variables d'environnement : `DJANGO_SETTINGS_MODULE=core.settings`

Démarrer le service : `net start django_api`

## Étape 4 - Configuration IIS

### Site API (Reverse Proxy) :
1. Créer un nouveau site : `api_site`
2. Chemin : `C:\Sites\api\current`
3. Port : 8080
4. IP : 192.168.11.243
5. Ajouter une règle de réécriture vers 127.0.0.1:8000

### Site Admin :
1. Créer un nouveau site : `admin_site`
2. Chemin : `C:\Sites\admin\current`
3. Port : 8081
4. IP : 192.168.11.243

### Site Mobile :
1. Créer un nouveau site : `mobile_site`
2. Chemin : `C:\Sites\mobile\current`
3. Port : 8082
4. IP : 192.168.11.243

## Étape 5 - Tests

### Vérifier les URLs :
- http://192.168.11.243:8080 → API Django
- http://192.168.11.243:8081 → Application Admin
- http://192.168.11.243:8082 → Application Mobile

### Vérifier les logs :
- Services Windows → django_api
- IIS Logs
- Console du navigateur pour les erreurs CORS

## Dépannage

### Erreurs courantes :
1. **Port déjà utilisé** : Changer le port ou arrêter le service
2. **404 sur Flutter** : Vérifier le web.config SPA Fallback
3. **502 Bad Gateway** : Service django_api non démarré
4. **Erreurs CORS** : Vérifier CORS_ALLOWED_ORIGINS dans settings.py

### Commandes utiles :
```powershell
# Redémarrer le service Django
net stop django_api
net start django_api

# Vérifier les ports utilisés
netstat -an | findstr :8080
netstat -an | findstr :8081
netstat -an | findstr :8082

# Logs IIS
Get-EventLog -LogName Application -Source "IIS*"
```

## Maintenance

### Mise à jour de l'API :
1. Arrêter le service : `net stop django_api`
2. Copier les nouveaux fichiers
3. Appliquer les migrations : `python manage.py migrate`
4. Redémarrer le service : `net start django_api`

### Mise à jour des applications Flutter :
1. Rebuild sur la machine de développement
2. Copier les nouveaux fichiers build/web
3. Redémarrer les sites IIS si nécessaire



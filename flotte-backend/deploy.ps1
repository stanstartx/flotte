# Script de déploiement Django pour le serveur 192.168.11.243
# À exécuter sur le serveur de production

Write-Host "=== Déploiement Django Flotte Auto ===" -ForegroundColor Green

# Étape 1: Créer l'environnement virtuel
Write-Host "1. Création de l'environnement virtuel..." -ForegroundColor Yellow
if (Test-Path "venv") {
    Write-Host "L'environnement virtuel existe déjà" -ForegroundColor Blue
} else {
    python -m venv venv
    Write-Host "Environnement virtuel créé" -ForegroundColor Green
}

# Étape 2: Activer l'environnement et installer les dépendances
Write-Host "2. Installation des dépendances..." -ForegroundColor Yellow
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt

# Étape 3: Migrations
Write-Host "3. Application des migrations..." -ForegroundColor Yellow
python manage.py migrate

# Étape 4: Collecte des fichiers statiques
Write-Host "4. Collecte des fichiers statiques..." -ForegroundColor Yellow
python manage.py collectstatic --noinput

# Étape 5: Test du serveur
Write-Host "5. Test du serveur Waitress..." -ForegroundColor Yellow
Write-Host "Le serveur va démarrer sur 127.0.0.1:8000" -ForegroundColor Blue
Write-Host "Appuyez sur Ctrl+C pour arrêter le test" -ForegroundColor Blue
waitress-serve --listen=127.0.0.1:8000 core.wsgi:application



# Script de déploiement Django pour la structure existante
# Backend Django pour les applications Flutter dans C:\inetpub\wwwroot

Write-Host "=== Déploiement Backend Django - Structure existante ===" -ForegroundColor Green

# Étape 1: Vérifier la structure existante
Write-Host "1. Vérification de la structure existante..." -ForegroundColor Yellow
$frontendPath = "C:\inetpub\wwwroot"
if (Test-Path $frontendPath) {
    Write-Host "✓ Frontend trouvé: $frontendPath" -ForegroundColor Green
    $folders = Get-ChildItem $frontendPath -Directory
    Write-Host "Dossiers trouvés:" -ForegroundColor Blue
    foreach ($folder in $folders) {
        Write-Host "  - $($folder.Name)" -ForegroundColor Blue
    }
} else {
    Write-Host "✗ Frontend non trouvé: $frontendPath" -ForegroundColor Red
    exit 1
}

# Étape 2: Créer le dossier backend
Write-Host "2. Création du dossier backend..." -ForegroundColor Yellow
$backendPath = "C:\inetpub\backend"
if (!(Test-Path $backendPath)) {
    New-Item -ItemType Directory -Path $backendPath -Force
    Write-Host "✓ Dossier backend créé: $backendPath" -ForegroundColor Green
} else {
    Write-Host "✓ Dossier backend existe déjà: $backendPath" -ForegroundColor Blue
}

# Étape 3: Copier le projet Django
Write-Host "3. Copie du projet Django..." -ForegroundColor Yellow
$sourcePath = "flotte-backend"
if (Test-Path $sourcePath) {
    Copy-Item -Path "$sourcePath\*" -Destination $backendPath -Recurse -Force
    Write-Host "✓ Projet Django copié vers $backendPath" -ForegroundColor Green
} else {
    Write-Host "✗ Projet Django non trouvé: $sourcePath" -ForegroundColor Red
    exit 1
}

# Étape 4: Configuration Django
Write-Host "4. Configuration Django..." -ForegroundColor Yellow
Set-Location $backendPath

# Créer l'environnement virtuel
if (!(Test-Path "venv")) {
    python -m venv venv
    Write-Host "✓ Environnement virtuel créé" -ForegroundColor Green
} else {
    Write-Host "✓ Environnement virtuel existe déjà" -ForegroundColor Blue
}

# Activer l'environnement et installer les dépendances
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt

# Migrations
Write-Host "5. Application des migrations..." -ForegroundColor Yellow
python manage.py migrate
python manage.py collectstatic --noinput

# Étape 6: Test du serveur
Write-Host "6. Test du serveur Django..." -ForegroundColor Yellow
Write-Host "Le serveur va démarrer sur 127.0.0.1:8000" -ForegroundColor Blue
Write-Host "Appuyez sur Ctrl+C pour arrêter le test" -ForegroundColor Blue
Write-Host "URLs de test:" -ForegroundColor Green
Write-Host "  - API: http://localhost:8000/api/" -ForegroundColor Blue
Write-Host "  - Admin: http://localhost:8000/admin/" -ForegroundColor Blue
Write-Host "  - Frontend Admin: http://localhost:8002" -ForegroundColor Blue
Write-Host "  - Frontend Conducteur: http://localhost:8001" -ForegroundColor Blue

waitress-serve --listen=127.0.0.1:8000 core.wsgi:application



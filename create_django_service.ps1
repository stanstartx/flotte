# Script de création du service Windows Django
# Pour la structure C:\inetpub\backend

Write-Host "=== Création du service Windows Django ===" -ForegroundColor Green

# Vérifier que NSSM est disponible
$nssmPath = "C:\Tools\nssm\nssm.exe"
if (!(Test-Path $nssmPath)) {
    Write-Host "⚠ NSSM non trouvé à $nssmPath" -ForegroundColor Yellow
    Write-Host "Téléchargez NSSM depuis: https://nssm.cc/download" -ForegroundColor Blue
    Write-Host "Ou installez-le dans C:\Tools\nssm\" -ForegroundColor Blue
    exit 1
}

# Vérifier que le projet Django existe
$djangoPath = "C:\inetpub\backend"
if (!(Test-Path $djangoPath)) {
    Write-Host "✗ Projet Django non trouvé: $djangoPath" -ForegroundColor Red
    Write-Host "Exécutez d'abord .\deploy_backend_local.ps1" -ForegroundColor Blue
    exit 1
}

# Vérifier que l'environnement virtuel existe
$venvPath = "$djangoPath\venv\Scripts\waitress-serve.exe"
if (!(Test-Path $venvPath)) {
    Write-Host "✗ Environnement virtuel non trouvé: $venvPath" -ForegroundColor Red
    Write-Host "Exécutez d'abord .\deploy_backend_local.ps1" -ForegroundColor Blue
    exit 1
}

# Créer le service
Write-Host "Création du service django_api..." -ForegroundColor Yellow
& $nssmPath install django_api $venvPath

# Configurer le service
Write-Host "Configuration du service..." -ForegroundColor Yellow
& $nssmPath set django_api AppDirectory $djangoPath
& $nssmPath set django_api AppParameters "--listen=127.0.0.1:8000 core.wsgi:application"
& $nssmPath set django_api AppEnvironmentExtra "DJANGO_SETTINGS_MODULE=core.settings"

# Démarrer le service
Write-Host "Démarrage du service..." -ForegroundColor Yellow
Start-Service django_api

# Vérifier le statut
$service = Get-Service django_api
if ($service.Status -eq "Running") {
    Write-Host "✓ Service django_api démarré avec succès" -ForegroundColor Green
} else {
    Write-Host "✗ Erreur lors du démarrage du service" -ForegroundColor Red
    Write-Host "Statut: $($service.Status)" -ForegroundColor Red
}

Write-Host "=== Service créé ===" -ForegroundColor Green
Write-Host "URLs disponibles:" -ForegroundColor Blue
Write-Host "  - API Django: http://localhost:8000/api/" -ForegroundColor Blue
Write-Host "  - Admin Django: http://localhost:8000/admin/" -ForegroundColor Blue
Write-Host "  - App Admin: http://localhost:8002" -ForegroundColor Blue
Write-Host "  - App Conducteur: http://localhost:8001" -ForegroundColor Blue

Write-Host "Commandes utiles:" -ForegroundColor Blue
Write-Host "  - Arrêter: net stop django_api" -ForegroundColor Blue
Write-Host "  - Démarrer: net start django_api" -ForegroundColor Blue
Write-Host "  - Redémarrer: Restart-Service django_api" -ForegroundColor Blue



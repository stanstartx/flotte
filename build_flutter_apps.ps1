# Script de build des applications Flutter pour le déploiement
# À exécuter sur votre machine de développement

Write-Host "=== Build des applications Flutter ===" -ForegroundColor Green

# Vérifier que Flutter est installé
Write-Host "1. Vérification de Flutter..." -ForegroundColor Yellow
flutter --version

# Build de l'application principale (Admin)
Write-Host "2. Build de l'application principale (Admin)..." -ForegroundColor Yellow
Set-Location "flotte"
flutter clean
flutter pub get
flutter build web --release
Write-Host "Build admin terminé dans flotte/build/web/" -ForegroundColor Green

# Build de l'application conducteur (Mobile)
Write-Host "3. Build de l'application conducteur (Mobile)..." -ForegroundColor Yellow
Set-Location "../application_conducteur"
flutter clean
flutter pub get
flutter build web --release
Write-Host "Build mobile terminé dans application_conducteur/build/web/" -ForegroundColor Green

# Retour au répertoire racine
Set-Location ".."

Write-Host "=== Build terminé ===" -ForegroundColor Green
Write-Host "Les dossiers build/web sont prêts pour le déploiement" -ForegroundColor Blue
Write-Host "Copiez le contenu de flotte/build/web/ vers C:\Sites\admin\current\" -ForegroundColor Blue
Write-Host "Copiez le contenu de application_conducteur/build/web/ vers C:\Sites\mobile\current\" -ForegroundColor Blue



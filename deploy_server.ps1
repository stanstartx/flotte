# Script de déploiement automatisé pour le serveur 192.168.11.243
# À exécuter sur le serveur de production

param(
    [string]$Action = "deploy"
)

Write-Host "=== Déploiement Flotte Auto - Serveur ===" -ForegroundColor Green

switch ($Action) {
    "deploy" {
        Write-Host "Mode: Déploiement complet" -ForegroundColor Blue
        
        # Étape 1: Créer l'arborescence
        Write-Host "1. Création de l'arborescence..." -ForegroundColor Yellow
        $directories = @(
            "C:\Sites\api\current",
            "C:\Sites\admin\current", 
            "C:\Sites\mobile\current"
        )
        
        foreach ($dir in $directories) {
            if (!(Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force
                Write-Host "✓ Créé: $dir" -ForegroundColor Green
            } else {
                Write-Host "✓ Existe déjà: $dir" -ForegroundColor Blue
            }
        }
        
        # Étape 2: Configuration Django
        Write-Host "2. Configuration Django..." -ForegroundColor Yellow
        Set-Location "C:\Sites\api\current"
        
        if (!(Test-Path "venv")) {
            python -m venv venv
            Write-Host "✓ Environnement virtuel créé" -ForegroundColor Green
        }
        
        .\venv\Scripts\Activate.ps1
        pip install -r requirements.txt
        python manage.py migrate
        python manage.py collectstatic --noinput
        
        # Étape 3: Créer le service Windows
        Write-Host "3. Configuration du service Windows..." -ForegroundColor Yellow
        if (!(Get-Service -Name "django_api" -ErrorAction SilentlyContinue)) {
            Write-Host "Service django_api non trouvé. Créez-le manuellement avec NSSM:" -ForegroundColor Yellow
            Write-Host "C:\Tools\nssm\nssm.exe install django_api" -ForegroundColor Blue
            Write-Host "Application Path: C:\Sites\api\current\venv\Scripts\waitress-serve.exe" -ForegroundColor Blue
            Write-Host "Arguments: --listen=127.0.0.1:8000 core.wsgi:application" -ForegroundColor Blue
        } else {
            Write-Host "✓ Service django_api existe" -ForegroundColor Green
        }
        
        # Étape 4: Vérifier IIS
        Write-Host "4. Vérification IIS..." -ForegroundColor Yellow
        $iisSites = @("api_site", "admin_site", "mobile_site")
        foreach ($site in $iisSites) {
            try {
                Import-Module WebAdministration
                $siteExists = Get-Website -Name $site -ErrorAction SilentlyContinue
                if ($siteExists) {
                    Write-Host "✓ Site IIS $site existe" -ForegroundColor Green
                } else {
                    Write-Host "⚠ Site IIS $site manquant - à créer manuellement" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "⚠ Impossible de vérifier IIS" -ForegroundColor Yellow
            }
        }
        
        Write-Host "=== Déploiement terminé ===" -ForegroundColor Green
        Write-Host "Prochaines étapes:" -ForegroundColor Blue
        Write-Host "1. Copier les fichiers build/web des applications Flutter" -ForegroundColor Blue
        Write-Host "2. Créer les sites IIS manuellement si nécessaire" -ForegroundColor Blue
        Write-Host "3. Démarrer le service django_api" -ForegroundColor Blue
        Write-Host "4. Exécuter .\test_deployment.ps1 pour vérifier" -ForegroundColor Blue
    }
    
    "test" {
        Write-Host "Mode: Test du déploiement" -ForegroundColor Blue
        .\test_deployment.ps1
    }
    
    "restart" {
        Write-Host "Mode: Redémarrage des services" -ForegroundColor Blue
        
        # Redémarrer le service Django
        if (Get-Service -Name "django_api" -ErrorAction SilentlyContinue) {
            Write-Host "Redémarrage du service django_api..." -ForegroundColor Yellow
            Restart-Service -Name "django_api"
            Write-Host "✓ Service django_api redémarré" -ForegroundColor Green
        }
        
        # Redémarrer IIS
        Write-Host "Redémarrage d'IIS..." -ForegroundColor Yellow
        iisreset
        Write-Host "✓ IIS redémarré" -ForegroundColor Green
    }
    
    default {
        Write-Host "Actions disponibles:" -ForegroundColor Blue
        Write-Host "  .\deploy_server.ps1 deploy    - Deploiement complet" -ForegroundColor Blue
        Write-Host "  .\deploy_server.ps1 test      - Test du deploiement" -ForegroundColor Blue
        Write-Host "  .\deploy_server.ps1 restart   - Redemarrage des services" -ForegroundColor Blue
    }
}

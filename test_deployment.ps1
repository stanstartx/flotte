# Script de test du déploiement
# À exécuter après avoir terminé toutes les étapes

Write-Host "=== Test du déploiement Flotte Auto ===" -ForegroundColor Green

# Test 1: Vérifier que les services sont démarrés
Write-Host "1. Vérification des services..." -ForegroundColor Yellow
$services = @("django_api", "W3SVC")
foreach ($service in $services) {
    $status = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($status) {
        Write-Host "✓ Service $service : $($status.Status)" -ForegroundColor Green
    } else {
        Write-Host "✗ Service $service non trouvé" -ForegroundColor Red
    }
}

# Test 2: Vérifier que les ports sont ouverts
Write-Host "2. Vérification des ports..." -ForegroundColor Yellow
$ports = @(8080, 8081, 8082)
foreach ($port in $ports) {
    $connection = Test-NetConnection -ComputerName "192.168.11.243" -Port $port -InformationLevel Quiet
    if ($connection) {
        Write-Host "✓ Port $port : Ouvert" -ForegroundColor Green
    } else {
        Write-Host "✗ Port $port : Fermé" -ForegroundColor Red
    }
}

# Test 3: Test des URLs
Write-Host "3. Test des URLs..." -ForegroundColor Yellow
$urls = @(
    @{Url="http://192.168.11.243:8080"; Name="API Django"},
    @{Url="http://192.168.11.243:8081"; Name="Admin Flutter"},
    @{Url="http://192.168.11.243:8082"; Name="Mobile Flutter"}
)

foreach ($url in $urls) {
    try {
        $response = Invoke-WebRequest -Uri $url.Url -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ $($url.Name) : OK (Status: $($response.StatusCode))" -ForegroundColor Green
        } else {
            Write-Host "⚠ $($url.Name) : Status $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ $($url.Name) : Erreur - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 4: Test de l'API Django
Write-Host "4. Test de l'API Django..." -ForegroundColor Yellow
try {
    $apiResponse = Invoke-WebRequest -Uri "http://192.168.11.243:8080/api/" -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✓ API Django répond correctement" -ForegroundColor Green
} catch {
    Write-Host "✗ Erreur API Django : $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=== Tests terminés ===" -ForegroundColor Green
Write-Host "Si tous les tests sont verts, votre déploiement est réussi !" -ForegroundColor Blue



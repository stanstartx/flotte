#!/bin/bash

# Configuration
API_URL="http://localhost:8000/api"
TOKEN=""
USERNAME="stan"  # Remplacez par votre nom d'utilisateur
PASSWORD="CI0114279081"  # Remplacez par votre mot de passe

# Fonction pour obtenir le token
get_token() {
    echo "🔑 Obtention du token JWT..."
    response=$(curl -s -X POST $API_URL/token/ \
        -H "Content-Type: application/json" \
        -d "{\"username\": \"$USERNAME\", \"password\": \"$PASSWORD\"}")
    
    echo "Réponse du serveur: $response"
    
    if [[ $response == *"access"* ]]; then
        TOKEN=$(echo $response | python3 -c "import sys, json; print(json.load(sys.stdin)['access'])")
        echo "✅ Token obtenu: $TOKEN"
    else
        echo "❌ Erreur lors de l'obtention du token"
        exit 1
    fi
}

# Fonction pour tester l'ajout d'une dépense
test_add_expense() {
    echo "💰 Test d'ajout d'une dépense..."
    response=$(curl -s -X POST $API_URL/expenses/ \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "vehicle": 1,
            "type": "carburant",
            "montant": 85.50,
            "date": "2024-03-21",
            "description": "Plein d'\''essence",
            "kilometrage": 50000
        }')
    echo "Réponse: $response"
    echo -e "\n"
}

# Fonction pour tester l'ajout d'un plein
test_add_fuel_log() {
    echo "⛽ Test d'ajout d'un plein..."
    response=$(curl -s -X POST $API_URL/fuellogs/ \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "vehicle": 1,
            "driver": 1,
            "date": "2024-03-21",
            "litres": 45.5,
            "cout": 85.50,
            "kilometrage": 50000,
            "station": "Total",
            "commentaire": "Plein complet"
        }')
    echo "Réponse: $response"
    echo -e "\n"
}

# Fonction pour tester les statistiques
test_consumption_stats() {
    echo "📊 Test des statistiques de consommation..."
    response=$(curl -s -X GET "$API_URL/fuellogs/consumption_stats/?vehicle_id=1" \
        -H "Authorization: Bearer $TOKEN")
    echo "Réponse: $response"
    echo -e "\n"
}

# Fonction pour tester la génération de rapport
test_generate_report() {
    echo "📈 Test de génération de rapport..."
    response=$(curl -s -X POST "$API_URL/reports/generate_report/" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{
            "vehicle_id": 1,
            "date_debut": "2024-01-01",
            "date_fin": "2024-03-21"
        }')
    echo "Réponse: $response"
    echo -e "\n"
}

# Exécution des tests
echo "🚀 Démarrage des tests..."
get_token
test_add_expense
test_add_fuel_log
test_consumption_stats
test_generate_report
echo "✅ Tests terminés!" 
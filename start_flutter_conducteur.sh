#!/bin/bash

echo "👨‍💼 Lancement de l'Application Conducteur..."

# Aller dans le dossier application_conducteur
cd application_conducteur

# Installer les dépendances
echo "📥 Installation des dépendances Flutter..."
flutter pub get

# Lancer l'application
echo "🚀 Lancement de l'application conducteur sur http://localhost:3001"
flutter run -d chrome --web-port 3001 
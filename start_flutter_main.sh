#!/bin/bash

echo "📱 Lancement de l'Application Flutter Principale..."

# Aller dans le dossier flotte
cd flotte

# Installer les dépendances
echo "📥 Installation des dépendances Flutter..."
flutter pub get

# Lancer l'application
echo "🚀 Lancement de l'application sur http://localhost:3000"
flutter run -d chrome --web-port 3000 
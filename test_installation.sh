#!/bin/bash

echo "🧪 TEST D'INSTALLATION - PROJET GESTION DE FLOTTE"
echo "================================================="

# Vérifier les prérequis
echo ""
echo "📋 Vérification des prérequis :"
echo "Python version :"
python3 --version
echo ""
echo "Flutter version :"
flutter --version
echo ""

# Vérifier les dossiers
echo "📁 Vérification des dossiers :"
if [ -d "flotte-backend" ]; then
    echo "✅ flotte-backend/ - OK"
else
    echo "❌ flotte-backend/ - MANQUANT"
fi

if [ -d "flotte" ]; then
    echo "✅ flotte/ - OK"
else
    echo "❌ flotte/ - MANQUANT"
fi

if [ -d "application_conducteur" ]; then
    echo "✅ application_conducteur/ - OK"
else
    echo "❌ application_conducteur/ - MANQUANT"
fi

# Vérifier les fichiers de configuration
echo ""
echo "⚙️ Vérification des fichiers de configuration :"
if [ -f "flotte-backend/requirements.txt" ]; then
    echo "✅ requirements.txt - OK"
else
    echo "❌ requirements.txt - MANQUANT"
fi

if [ -f "flotte/pubspec.yaml" ]; then
    echo "✅ pubspec.yaml (flotte) - OK"
else
    echo "❌ pubspec.yaml (flotte) - MANQUANT"
fi

if [ -f "application_conducteur/pubspec.yaml" ]; then
    echo "✅ pubspec.yaml (conducteur) - OK"
else
    echo "❌ pubspec.yaml (conducteur) - MANQUANT"
fi

# Vérifier les ports
echo ""
echo "🔌 Vérification des ports :"
if netstat -tulpn 2>/dev/null | grep :8000 > /dev/null; then
    echo "❌ Port 8000 déjà utilisé"
else
    echo "✅ Port 8000 disponible"
fi

if netstat -tulpn 2>/dev/null | grep :3000 > /dev/null; then
    echo "❌ Port 3000 déjà utilisé"
else
    echo "✅ Port 3000 disponible"
fi

if netstat -tulpn 2>/dev/null | grep :3001 > /dev/null; then
    echo "❌ Port 3001 déjà utilisé"
else
    echo "✅ Port 3001 disponible"
fi

echo ""
echo "🎯 RÉSUMÉ :"
echo "Pour lancer le projet complet :"
echo "1. ./start_backend.sh (dans un terminal)"
echo "2. ./start_flutter_main.sh (dans un autre terminal)"
echo "3. ./start_flutter_conducteur.sh (dans un troisième terminal)"
echo ""
echo "📖 Consultez GUIDE_LANCEMENT.md pour plus de détails" 
#!/bin/bash

echo "🎯 LANCEMENT COMPLET DU PROJET GESTION DE FLOTTE"
echo "================================================"

# Rendre les scripts exécutables
chmod +x start_backend.sh
chmod +x start_flutter_main.sh
chmod +x start_flutter_conducteur.sh

echo ""
echo "📋 Instructions de lancement :"
echo "1. Ouvrez 3 terminaux différents"
echo "2. Dans le terminal 1 : ./start_backend.sh"
echo "3. Dans le terminal 2 : ./start_flutter_main.sh"
echo "4. Dans le terminal 3 : ./start_flutter_conducteur.sh"
echo ""
echo "🌐 URLs d'accès :"
echo "- Backend API : http://localhost:8000"
echo "- Application Admin/Gestionnaire : http://localhost:3000"
echo "- Application Conducteur : http://localhost:3001"
echo ""
echo "🔑 Identifiants de test (à créer si nécessaire) :"
echo "- Admin : admin/admin123"
echo "- Gestionnaire : gestionnaire/gestion123"
echo "- Conducteur : conducteur/conducteur123"
echo ""
echo "⚠️ Assurez-vous que les ports 8000, 3000 et 3001 sont disponibles" 
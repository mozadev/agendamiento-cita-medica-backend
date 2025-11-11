#!/bin/bash

# Script para hacer push con Personal Access Token
# Uso: ./push-with-token.sh TU_TOKEN_AQUI

if [ -z "$1" ]; then
    echo "❌ Error: Debes proporcionar el token"
    echo ""
    echo "Uso:"
    echo "  ./push-with-token.sh TU_TOKEN_AQUI"
    echo ""
    echo "Ejemplo:"
    echo "  ./push-with-token.sh ghp_xxxxxxxxxxxxxxxxxxxx"
    exit 1
fi

TOKEN=$1

echo "🔐 Configurando remoto con token..."
git remote set-url origin https://${TOKEN}@github.com/mozadev/agendamiento-cita-medica-backend.git

echo "🚀 Haciendo push..."
git push -u origin main

echo ""
echo "✅ Push completado!"
echo ""
echo "🔒 Limpiando token de la URL del remoto (por seguridad)..."
git remote set-url origin https://github.com/mozadev/agendamiento-cita-medica-backend.git

echo ""
echo "✨ Listo! El token se guardó en el keychain de macOS"
echo "   Los próximos pushes no necesitarán el token de nuevo"


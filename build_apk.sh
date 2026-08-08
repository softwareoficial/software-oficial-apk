#!/bin/bash

# Script para automatizar la preparación y compilación del proyecto Flutter
# Ubicación: raíz del proyecto

echo "--- Iniciando proceso de compilación de Flutter ---"

# 1. Limpiar el proyecto
echo "-> Limpiando proyecto..."
flutter clean

# 2. Obtener dependencias
echo "-> Obteniendo dependencias..."
flutter pub get

# 3. Compilar APK Debug para ARMv7
echo "-> Compilando APK Debug (ARMv7)..."
flutter build apk --debug --target-platform android-arm

if [ $? -eq 0 ]; then
    echo "--- Compilación completada con éxito ---"
    echo "El archivo APK se encuentra en: build/app/outputs/flutter-apk/app-debug.apk"
else
    echo "--- Error durante la compilación ---"
    exit 1
fi

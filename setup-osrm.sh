#!/bin/bash

# Script para configurar OSRM localmente con Docker
# Asegúrate de que Docker Desktop esté corriendo antes de ejecutar

set -e

echo "🚀 Configurando OSRM Server Local"
echo "=================================="
echo ""

# Verificar que Docker esté corriendo
if ! docker ps > /dev/null 2>&1; then
    echo "❌ Error: Docker no está corriendo"
    echo "Por favor inicia Docker Desktop y vuelve a ejecutar este script"
    exit 1
fi

# Verificar que el archivo OSM existe
if [ ! -f "uruguay-251117.osm.pbf" ]; then
    echo "❌ Error: No se encuentra el archivo uruguay-251117.osm.pbf"
    echo "Asegúrate de estar en el directorio correcto"
    exit 1
fi

echo "✓ Docker está corriendo"
echo "✓ Archivo OSM encontrado: uruguay-251117.osm.pbf"
echo ""

# Descargar la imagen más reciente de OSRM
echo "📦 Descargando imagen de OSRM..."
docker pull ghcr.io/project-osrm/osrm-backend:latest

# Extraer datos del mapa
echo ""
echo "🗺️  Extrayendo datos del mapa (esto puede tomar varios minutos)..."
docker run -t -v $(pwd):/data ghcr.io/project-osrm/osrm-backend:latest \
    osrm-extract -p /opt/car.lua /data/uruguay-251117.osm.pbf

if [ $? -eq 0 ]; then
    echo "✓ Extracción completada exitosamente"
else
    echo "❌ Error en la extracción"
    exit 1
fi

# Contraer el grafo
echo ""
echo "📊 Contrayendo el grafo (optimización)..."
docker run -t -v $(pwd):/data ghcr.io/project-osrm/osrm-backend:latest \
    osrm-contract /data/uruguay-251117.osrm

if [ $? -eq 0 ]; then
    echo "✓ Contracción completada exitosamente"
else
    echo "❌ Error en la contracción"
    exit 1
fi

echo ""
echo "🎉 ¡Configuración completada!"
echo ""
echo "Para iniciar el servidor OSRM, ejecuta:"
echo "  ./start-osrm.sh"
echo ""
echo "O manualmente:"
echo "  docker run -t -i -p 5555:5000 -v \$(pwd):/data ghcr.io/project-osrm/osrm-backend:latest osrm-routed --algorithm mld /data/uruguay-251117.osrm"

#!/bin/bash

# Script para iniciar el servidor OSRM local
# Puerto 5555 para evitar conflicto con Rails (puerto 3000)

echo "🚀 Iniciando servidor OSRM local..."
echo "=================================="
echo ""

# Verificar que Docker esté corriendo
if ! docker ps > /dev/null 2>&1; then
    echo "❌ Error: Docker no está corriendo"
    echo "Por favor inicia Docker Desktop y vuelve a ejecutar este script"
    exit 1
fi

# Verificar que los archivos procesados existan
if [ ! -f "uruguay-251117.osrm.hsgr" ]; then
    echo "❌ Error: No se encuentra uruguay-251117.osrm.hsgr"
    echo "Primero debes ejecutar: ./setup-osrm.sh"
    exit 1
fi

echo "✓ Docker está corriendo"
echo "✓ Archivos OSRM encontrados"
echo ""
echo "🌐 Iniciando servidor en http://localhost:5555"
echo "   (Puerto 5555 para no chocar con Rails en 3000)"
echo ""
echo "Para detener el servidor, presiona Ctrl+C"
echo ""

# Iniciar servidor OSRM
# Usamos puerto 5555 en el host para mapear al 5000 del contenedor
# Usa --rm para eliminar el contenedor al detenerlo
# Usa --algorithm ch (contraction hierarchies) que generó el archivo .hsgr
docker run --rm -t -i -p 5555:5000 -v $(pwd):/data ghcr.io/project-osrm/osrm-backend:latest \
    osrm-routed --algorithm ch /data/uruguay-251117.osrm

echo ""
echo "Servidor OSRM detenido"

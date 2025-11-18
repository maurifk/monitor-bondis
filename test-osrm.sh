#!/bin/bash

# Script para probar que el servidor OSRM esté funcionando correctamente

echo "🧪 Probando servidor OSRM..."
echo "=============================="
echo ""

# URL del servidor (usar variable de entorno o localhost:5555 por defecto)
OSRM_URL="${OSRM_URL:-http://localhost:5555}"

echo "Servidor: $OSRM_URL"
echo ""

# Coordenadas de prueba en Montevideo:
# Plaza Independencia: -56.1645, -34.9011
# Obelisco: -56.1679, -34.9058
TEST_COORDS="-56.1645,-34.9011;-56.1679,-34.9058"

echo "Probando ruta: Plaza Independencia → Obelisco"
echo ""

# Hacer consulta
response=$(curl -s -w "\n%{http_code}" "$OSRM_URL/route/v1/driving/$TEST_COORDS")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ]; then
    echo "✅ Servidor OSRM funcionando correctamente"
    echo ""
    
    # Extraer información de la respuesta
    if command -v jq &> /dev/null; then
        duration=$(echo "$body" | jq -r '.routes[0].duration')
        distance=$(echo "$body" | jq -r '.routes[0].distance')
        
        duration_min=$(echo "scale=1; $duration / 60" | bc)
        distance_km=$(echo "scale=2; $distance / 1000" | bc)
        
        echo "📊 Resultado:"
        echo "   Duración: ${duration_min} minutos (${duration} segundos)"
        echo "   Distancia: ${distance_km} km (${distance} metros)"
    else
        echo "📊 Respuesta del servidor:"
        echo "$body" | head -c 200
        echo "..."
        echo ""
        echo "💡 Instala 'jq' para ver la respuesta formateada: brew install jq"
    fi
else
    echo "❌ Error: Servidor no respondió correctamente"
    echo "   Código HTTP: $http_code"
    echo ""
    
    if [ "$http_code" = "000" ]; then
        echo "   El servidor no está accesible. Verifica que esté corriendo:"
        echo "   ./start-osrm.sh"
    else
        echo "   Respuesta:"
        echo "$body"
    fi
    
    exit 1
fi

echo ""
echo "🎉 ¡Todo OK!"

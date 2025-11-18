# Ejemplo de Estimación de Tiempos de Llegada

## Cómo Funciona el Sistema

### 1. Flujo de Datos

```
Usuario busca parada → Selecciona parada
    ↓
Sistema obtiene variantes que pasan por esa parada
    ↓
Para cada línea, obtiene buses en tiempo real (API STM)
    ↓
Para cada bus:
  - Calcula próxima parada (método mejorado por segmentos)
  - Verifica si aún no pasó por la parada objetivo
  - Obtiene paradas intermedias entre próxima y objetivo
  - Consulta OSRM con: [posición_bus, ...paradas_intermedias, parada_objetivo]
  - OSRM retorna: duración, distancia, geometría de ruta
    ↓
Muestra buses ordenados por tiempo de llegada
```

### 2. Ejemplo de Consulta OSRM

**Entrada:**
```ruby
bus_location = [-56.1645, -34.9011]  # Posición actual del bus
intermediate_stops = [
  BusStop(lat: -34.9025, lon: -56.1660),
  BusStop(lat: -34.9040, lon: -56.1675)
]
target_stop = BusStop(lat: -34.9058, lon: -56.1679)

OsrmService.estimate_arrival_time(bus_location, intermediate_stops, target_stop)
```

**Salida:**
```ruby
{
  duration_seconds: 180,
  duration_minutes: 3,
  distance_meters: 1250,
  distance_km: 1.25,
  estimated_arrival: 2025-11-18 02:46:00 UTC
}
```

### 3. Visualización en la Vista

Para cada bus que se aproxima:

```
┌─────────────────────────────────────────────────┐
│ Línea 21 - Bondi #1234              [ 5 min ]  │
│ CUTCSA                              [ 14:48 ]   │
│─────────────────────────────────────────────────│
│ Origen: Terminal Colón                          │
│ Destino: Pocitos                                │
│─────────────────────────────────────────────────│
│ 📍 Próxima parada: 18 de Julio y Rio Negro      │
│ 🚗 Distancia: 2.3 km                            │
│─────────────────────────────────────────────────│
│ Velocidad: 35 km/h                              │
│ Actualizado: 14:43:15                           │
└─────────────────────────────────────────────────┘
```

### 4. Algoritmo de Estimación de Próxima Parada

El sistema usa un algoritmo basado en **distancia perpendicular a segmentos**:

1. Toma todas las paradas en orden del recorrido
2. Para cada par consecutivo de paradas (segmento):
   - Calcula la distancia perpendicular del bus al segmento
3. Encuentra el segmento más cercano
4. La próxima parada es el **destino** de ese segmento

**Ventaja:** Si el bus está cerca pero antes de una parada, correctamente identifica que la próxima parada es esa (no la siguiente).

### 5. Casos de Uso

#### Caso 1: Bus yendo hacia la parada
- Próxima parada: Parada A
- Parada objetivo: Parada D
- Paradas intermedias: B, C
- Resultado: ✅ Muestra tiempo estimado considerando A → B → C → D

#### Caso 2: Bus ya pasó la parada
- Próxima parada: Parada E
- Parada objetivo: Parada D
- Resultado: ❌ No se muestra (el bus ya pasó)

#### Caso 3: Próxima parada ES la parada objetivo
- Próxima parada: Parada D
- Parada objetivo: Parada D
- Paradas intermedias: [] (ninguna)
- Resultado: ✅ Muestra tiempo directo + badge "¡Esta parada!"

### 6. Personalización

Para usar un servidor OSRM local:

```ruby
# app/services/osrm_service.rb
BASE_URL = "http://localhost:5000"  # Tu servidor OSRM local
```

### 7. Consideraciones

- **Timeout:** Las consultas a OSRM tienen timeout de 10 segundos
- **Manejo de errores:** Si OSRM falla, el bus se muestra sin tiempo estimado
- **Precisión:** Los tiempos son estimaciones basadas en rutas ideales, no consideran tráfico en tiempo real
- **Paradas intermedias:** Se incluyen TODAS las paradas entre la próxima y la objetivo para mayor precisión

# Nueva Funcionalidad: Búsqueda de Paradas

## Descripción

Se ha agregado una nueva vista que permite buscar paradas y ver qué ómnibus están aproximándose a ellas.

## Funcionalidades

### 1. Búsqueda de Paradas (`/stops`)

Permite buscar paradas por:
- Nombre de calles (street1 o street2)
- ID de parada (busstop_id)

La búsqueda es insensible a mayúsculas/minúsculas y muestra hasta 50 resultados.

### 2. Vista de Parada Individual (`/stops/:id`)

Al seleccionar una parada, muestra:
- Información de la parada (nombre, ID, ubicación)
- Líneas que pasan por esa parada
- **Lista de ómnibus aproximándose** que cumplen:
  - Pertenecen a una variante que pasa por esa parada
  - Su próxima parada es la parada seleccionada o una anterior en el recorrido
  - Muestra cuál es la próxima parada de cada ómnibus

### 3. Algoritmo de Estimación de Próxima Parada

**Método:** `LineVariant#estimate_next_stop(latitude, longitude)`

Mejora implementada:
- Calcula la distancia del bus a cada **segmento** (par de paradas consecutivas)
- Encuentra el segmento más cercano usando distancia perpendicular
- Devuelve la parada destino de ese segmento

Esto soluciona el problema anterior donde si el bus estaba cerca pero antes de una parada, devolvía la siguiente en lugar de la actual.

**Método auxiliar:** `LineVariant#stop_comes_before_or_at?(stop_a_id, stop_b_id)`

Verifica si una parada viene antes o es la misma que otra en el orden del recorrido de la variante.

## Rutas

- `GET /stops` - Buscar paradas
- `GET /stops/:id` - Ver detalles de parada y ómnibus aproximándose

## Navegación

Se agregó una barra de navegación en el layout principal con enlaces a:
- Buscar Línea (vista principal)
- Buscar Parada (nueva vista)

## Archivos Modificados

1. **Servicios:**
   - `app/services/osrm_service.rb` - Nuevo servicio para integración con OSRM
2. **Controladores:**
   - `app/controllers/stops_controller.rb` - Cálculo de tiempos de llegada
   - `app/controllers/buses_controller.rb` - Enriquecimiento con próxima parada
3. **Modelo:** `app/models/line_variant.rb`
   - `estimate_next_stop(lat, lng)` - Mejorado con cálculo por segmentos
   - `stop_comes_before_or_at?(stop_a, stop_b)` - Comparación de orden
   - `stops_between(from, to)` - Obtener paradas intermedias
   - `point_to_segment_distance(...)` - Cálculo geométrico
4. **Vistas:**
   - `app/views/stops/index.html.erb` - Búsqueda de paradas
   - `app/views/stops/show.html.erb` - Detalles, ómnibus y tiempos de llegada
   - `app/views/buses/_buses_list.html.erb` - Muestra próxima parada
   - `app/views/layouts/application.html.erb` - Navegación agregada
5. **Rutas:** `config/routes.rb`

## Estimación de Tiempos de Llegada (OSRM)

**Servicio:** `OsrmService`

Se integró con OSRM (Open Source Routing Machine) para calcular tiempos de llegada reales considerando:
- Posición actual del ómnibus
- Todas las paradas intermedias entre la próxima parada del bus y la parada objetivo
- Rutas de calles reales (no distancia en línea recta)

**Métodos:**
- `get_route(coordinates)` - Calcula ruta entre múltiples puntos
- `estimate_arrival_time(bus_location, intermediate_stops, target_stop)` - Estima tiempo de llegada

**Datos retornados:**
- `duration_minutes` - Minutos estimados de llegada
- `duration_seconds` - Segundos totales
- `distance_km` - Distancia en kilómetros
- `estimated_arrival` - Hora estimada de llegada

**URL OSRM:** Por defecto usa el servidor público `https://router.project-osrm.org` (se puede cambiar a servidor local)

Los ómnibus en la vista de parada se ordenan automáticamente por tiempo de llegada estimado (más cercanos primero).

## Uso

1. Ir a `/stops` o hacer clic en "Buscar Parada" en el menú
2. Buscar una parada por calle o ID
3. Hacer clic en una parada de los resultados
4. Ver la lista de ómnibus que están yendo hacia esa parada
5. Cada ómnibus muestra:
   - Su próxima parada
   - **Tiempo estimado de llegada en minutos**
   - **Hora estimada de llegada**
   - **Distancia total a recorrer**
6. Los ómnibus están ordenados por tiempo de llegada (más cercanos primero)

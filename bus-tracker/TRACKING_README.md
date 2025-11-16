# Bus Tracking System

Sistema de tracking en tiempo real de ómnibus del STM de Montevideo.

## Características

- **Tracking en tiempo real**: Monitorea la ubicación de buses específicos cerca de una parada
- **Historial de posiciones**: Guarda las últimas 30 posiciones de cada bus
- **Estimación de llegada**: Calcula el tiempo estimado de llegada basado en velocidad promedio
- **Dashboard web**: Visualización en tiempo real de los buses trackeados
- **Worker de fondo**: Proceso que consulta la API cada 15 segundos

## Modelos

### BusTracking
Representa un bus que está siendo trackeado en relación a una parada específica.

**Campos:**
- `bus_stop_id`: Parada que se está monitoreando
- `bus_id`: ID único del bus
- `line`: Número de línea (ej: "147")
- `line_variant_id`: ID de la variante de la línea
- `latitude/longitude`: Última posición conocida
- `distance_to_stop`: Distancia actual a la parada (en metros)
- `speed`: Velocidad actual (km/h)
- `api_timestamp`: Timestamp del último dato de la API
- `last_seen_at`: Última vez que se vio el bus
- `tracking_active`: Si el tracking está activo
- `missing_count`: Contador de veces que no apareció en la API

### BusPosition
Historial de posiciones de un bus trackeado (máximo 30 posiciones).

**Campos:**
- `bus_tracking_id`: Referencia al tracking
- `latitude/longitude`: Coordenadas de la posición
- `distance_to_stop`: Distancia a la parada en ese momento
- `speed`: Velocidad en ese momento
- `api_timestamp`: Timestamp de la API

## Uso

### Desde la Web

1. Acceder a `/tracking`
2. Seleccionar una parada
3. Ingresar las líneas a monitorear (separadas por coma)
4. Opcionalmente, especificar IDs de variantes
5. Click en "Iniciar Tracking"
6. Ver el dashboard con actualizaciones en tiempo real

### Desde la Consola (Rake Tasks)

#### Iniciar tracking
```bash
# Sintaxis 1: Con argumentos
rails tracking:start[1478,'147,148,149']
rails tracking:start[1478,'147,148,149','4420,4424,4426']

# Sintaxis 2: Con variables de entorno
STOP_ID=1478 LINES='147,148,149' rails tracking:start
STOP_ID=1478 LINES='147,148,149' VARIANTS='4420,4424' rails tracking:start
```

#### Ver estado del tracking
```bash
rails tracking:status
```

#### Detener tracking
```bash
rails tracking:stop[1478]
# o
STOP_ID=1478 rails tracking:stop
```

### Desde Rails Console

```ruby
# Iniciar tracking
bus_stop = BusStop.find_by(busstop_id: 1478)
lines = ['147', '148', '149']
variants = ['4420', '4424', '4426']  # opcional

TrackBusesJob.perform_later(bus_stop.id, lines, variants)

# Ver buses activos
trackings = BusTracking.active.for_stop(bus_stop.id)
trackings.each do |t|
  puts "Bus #{t.bus_id} - Línea #{t.line} - #{t.distance_to_stop.to_i}m - ETA: #{t.estimated_minutes_to_arrival}min"
end

# Ver posiciones de un bus
tracking = BusTracking.find_by(bus_id: 971)
tracking.bus_positions.recent(10).each do |pos|
  puts "#{pos.api_timestamp}: #{pos.distance_to_stop.to_i}m"
end
```

## Funcionamiento

### Worker (TrackBusesJob)

1. **Consulta la API** cada 15 segundos pidiendo buses de las líneas especificadas
2. **Procesa cada bus**:
   - Si el timestamp es nuevo, crea una nueva posición
   - Calcula la distancia a la parada
   - Actualiza el registro de tracking
   - Mantiene solo las últimas 30 posiciones
3. **Marca buses faltantes**:
   - Si un bus no aparece, incrementa `missing_count`
   - Después de 3 veces, marca el tracking como inactivo

### Cálculo de Velocidad y ETA

El sistema **ignora el campo `speed` de la API** (es incorrecto) y calcula la velocidad real:

1. **Cálculo de velocidad promedio**:
   - Toma las últimas 10 posiciones
   - Calcula cambios de distancia entre posiciones consecutivas
   - Divide por el tiempo transcurrido
   - Solo considera mediciones donde la distancia disminuyó (acercándose)
   - Convierte a km/h
   - Requiere al menos 2 posiciones

2. **Detección de paso por parada**:
   - Analiza las últimas 5 posiciones
   - Si en 4 de las 4 transiciones la distancia aumentó, el bus pasó
   - Buses que pasaron siguen siendo trackeados pero no se muestran en el dashboard
   - Si vuelven a acercarse, se muestran nuevamente

3. **Estimación de llegada (ETA)**:
   - Usa la velocidad promedio calculada
   - Divide distancia actual / velocidad
   - No calcula ETA si el bus ya pasó
   - Requiere al menos 3 posiciones para ser confiable

### API Consultada

Endpoint: `GET https://mvdapi.montevideo.gub.uy/buses`

Parámetros:
- `lines`: Lista de líneas separadas por coma (ej: "147,148,149")
- `lineVariantIds`: (Opcional) Lista de IDs de variantes

Respuesta: Array de objetos con:
- `busId`: ID del bus
- `line`: Número de línea
- `lineVariantId`: ID de la variante
- `location.coordinates`: [longitud, latitud]
- `speed`: Velocidad en km/h
- `timestamp`: Timestamp ISO 8601
- `destination`, `origin`, `subline`, etc.

## Base de Datos

### Índices optimizados
- `idx_bus_trackings_stop_bus`: Para buscar tracking por parada y bus
- `idx_bus_trackings_stop_active`: Para filtrar trackings activos por parada
- `idx_bus_positions_tracking_time`: Para consultar posiciones por tiempo

### Limpieza automática
- Solo se mantienen las últimas 30 posiciones por bus
- Los trackings inactivos se mantienen para historial pero no se actualizan

## Ejemplo de Uso Completo

```bash
# 1. Iniciar tracking desde consola
STOP_ID=1478 LINES='147,148,149' rails tracking:start

# En otra terminal, ver el estado
rails tracking:status

# 2. O usar la web
rails server
# Acceder a http://localhost:3000/tracking

# 3. Ver dashboard con actualizaciones automáticas
# http://localhost:3000/tracking/dashboard?bus_stop_id=1
```

## Troubleshooting

### No aparecen buses
- Verificar que las líneas especificadas pasen por la parada
- Verificar que haya buses circulando (horario, día de la semana)
- Revisar logs: `rails tracking:status`

### ETA no se calcula
- Se necesitan al menos 3 posiciones
- Verificar que el bus se esté acercando (distancia disminuyendo)
- Si la distancia aumenta en las últimas 5 mediciones, el bus ya pasó
- Esperar unos minutos para acumular datos

### Bus desaparece del dashboard pero sigue trackeado
- Esto es normal: el bus pasó por la parada (distancia aumentando)
- El sistema sigue trackeándolo en caso de que vuelva a acercarse
- Puede ver buses que pasaron en los logs con `rails tracking:status`

### Tracking se detiene
- El job corre indefinidamente hasta que se detenga manualmente
- Si el proceso del worker se detiene, el job se detiene
- Usa Solid Queue (Rails 8) para gestión de trabajos en background

## Cómo iniciar el sistema correctamente

### Opción 1: Con workers en background (RECOMENDADO)

```bash
# Esto inicia web + css + worker en paralelo
bin/dev-with-workers
```

O manualmente en terminales separadas:
```bash
# Terminal 1: Web server
rails server

# Terminal 2: CSS (Tailwind)
rails tailwindcss:watch

# Terminal 3: Worker para jobs
bundle exec rake solid_queue:start
```

### Opción 2: Solo para pruebas rápidas desde consola

```bash
# Esto ejecuta el tracking de forma síncrona (bloquea el proceso)
rails tracking:start[1478,'147,148,149']
```

**IMPORTANTE**: Si inicias tracking desde la web sin el worker corriendo, verás este error:
```
No jobs are being processed. Start a worker with: bundle exec rake solid_queue:start
```

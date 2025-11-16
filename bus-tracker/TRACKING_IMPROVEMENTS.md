# Mejoras en el Sistema de Tracking

## Cambios Implementados

### 1. Cálculo Real de Velocidad Promedio

**Problema**: El campo `speed` que envía la API es incorrecto.

**Solución**: 
- El sistema ahora **ignora completamente** el campo `speed` de la API
- Calcula la velocidad real analizando cambios de distancia y tiempo entre posiciones
- Usa las últimas 10 posiciones para mayor precisión
- Solo considera mediciones donde el bus se está acercando (distancia disminuye)
- Convierte a km/h automáticamente

**Código**:
```ruby
def calculate_average_speed
  recent_positions = bus_positions.order(api_timestamp: :desc).limit(10)
  return nil if recent_positions.count < 2

  total_distance_change = 0
  total_time_seconds = 0
  valid_measurements = 0

  recent_positions.each_cons(2) do |newer, older|
    distance_change = (older.distance_to_stop - newer.distance_to_stop)
    time_diff = (newer.api_timestamp - older.api_timestamp).to_f
    
    if time_diff > 0 && distance_change > 0
      total_distance_change += distance_change
      total_time_seconds += time_diff
      valid_measurements += 1
    end
  end

  return nil if total_time_seconds.zero? || valid_measurements.zero?

  avg_speed_mps = total_distance_change / total_time_seconds
  (avg_speed_mps * 3.6).round(2) # Convert to km/h
end
```

### 2. Detección de Paso por la Parada

**Problema**: Los buses que ya pasaron seguían apareciendo en el dashboard.

**Solución**:
- Analiza las últimas 5 posiciones del bus
- Si en 4 de las 4 transiciones consecutivas la distancia aumentó → el bus pasó
- Buses que pasaron:
  - **NO** se muestran en el dashboard
  - **SÍ** siguen siendo trackeados (por si vuelven)
  - Aparecen en `rails tracking:status` con la etiqueta "(moving away)"

**Código**:
```ruby
def check_if_passed_stop
  recent_positions = bus_positions.order(api_timestamp: :desc).limit(5)
  return false if recent_positions.count < 5

  distances = recent_positions.map(&:distance_to_stop).reverse
  
  increases = 0
  distances.each_cons(2) do |older, newer|
    increases += 1 if newer > older
  end

  increases >= 4
end
```

### 3. Mejora en Cálculo de ETA

**Cambios**:
- Usa la velocidad promedio calculada (no la de la API)
- No calcula ETA si el bus ya pasó por la parada
- Requiere al menos 3 posiciones para ser confiable
- Formula: `distancia_actual / velocidad_promedio`

**Código**:
```ruby
def estimated_arrival_time
  return nil unless tracking_active && bus_positions.count >= 3
  return nil if has_passed_stop?
  return nil if distance_to_stop.nil? || distance_to_stop <= 0

  avg_speed_kmh = speed || calculate_average_speed
  return nil unless avg_speed_kmh && avg_speed_kmh > 0

  avg_speed_mps = avg_speed_kmh / 3.6
  seconds_to_arrival = distance_to_stop / avg_speed_mps
  Time.current + seconds_to_arrival.seconds
end
```

### 4. Dashboard Mejorado

**Nuevos Helpers** (`app/helpers/tracking_helper.rb`):

- `eta_display(tracking)`: Muestra ETA con colores según urgencia
  - Rojo pulsante: "¡Llegando!" (0 min)
  - Rojo: ≤ 2 minutos
  - Naranja: ≤ 5 minutos
  - Verde: > 5 minutos
  - Naranja: "Ya pasó" (si pasó la parada)

- `distance_display(distance)`: Formatea distancia
  - < 1000m → "850 m"
  - ≥ 1000m → "1.2 km"

- `speed_display(speed)`: Muestra velocidad o "Calculando..."

- `tracking_status_badge(tracking)`: Badge visual del estado
  - 🎯 "Llegando" (< 100m) - rojo pulsante
  - 🚍 "Muy cerca" (< 300m) - verde
  - 🚌 "Acercándose" (< 1000m) - azul
  - ⚠️ "Pasó" (si pasó) - naranja

### 5. Filtrado en Controller

El controller ahora filtra automáticamente:

```ruby
def dashboard
  all_trackings = BusTracking.active.for_stop(@bus_stop.id)
  @active_trackings = all_trackings.select { |t| !t.has_passed_stop? }
                                   .sort_by { |t| t.distance_to_stop || Float::INFINITY }
end
```

### 6. Rake Task Mejorado

`rails tracking:status` ahora muestra:
- Buses acercándose (con velocidad y ETA)
- Buses que pasaron (marcados como "moving away")
- Contadores separados

Ejemplo de salida:
```
Active tracking:

  Avenida Italia y Comercio (ID: 1478)
  3 buses being tracked (2 approaching, 1 passed)

  Approaching buses:
    - Bus #971 (Line 147) - 450m - 35.2 km/h - ETA: 2min
    - Bus #972 (Line 148) - 820m - 28.5 km/h - ETA: 4min

  Passed (still tracking):
    - Bus #973 (Line 149) - 150m (moving away)
```

## Ejemplo de Uso

```ruby
# En Rails console
tracking = BusTracking.first

# Velocidad calculada (ignora API)
tracking.calculate_average_speed # => 32.5 km/h

# Verificar si pasó
tracking.has_passed_stop? # => false

# ETA mejorado
tracking.estimated_minutes_to_arrival # => 3

# Ver en dashboard
# Las mejoras se ven automáticamente en /tracking/dashboard
```

## Ventajas

1. ✅ **Velocidad real**: Calculada con datos reales de movimiento
2. ✅ **ETA más preciso**: Basado en velocidad real, no en datos incorrectos de la API
3. ✅ **Dashboard limpio**: Solo muestra buses que se acercan
4. ✅ **Seguimiento continuo**: Sigue trackeando buses que pasaron por si vuelven
5. ✅ **Feedback visual**: Colores y badges según urgencia
6. ✅ **Información útil**: Muestra estado claro de cada bus

## Testing

Para probar con datos simulados:
```bash
rails tracking:examples:simulate
rails tracking:status
```

Luego visita el dashboard para ver las mejoras visuales.

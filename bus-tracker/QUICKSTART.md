# Bus Tracker - Inicio Rápido 🚌

## Pre-requisitos

1. Rails 8+ instalado
2. PostgreSQL corriendo
3. Variables de entorno configuradas (`.env`):
   ```
   CLIENT_ID=tu_client_id
   CLIENT_SECRET=tu_client_secret
   ```

## Iniciar el Sistema Completo

### Opción 1: Un solo comando (RECOMENDADO)

```bash
./bin/dev-with-workers
```

Esto inicia:
- ✅ Web server (puerto 3000)
- ✅ CSS watcher (Tailwind)
- ✅ Worker para jobs en background

### Opción 2: Manualmente (3 terminales)

**Terminal 1 - Web:**
```bash
rails server
```

**Terminal 2 - CSS:**
```bash
rails tailwindcss:watch
```

**Terminal 3 - Worker (IMPORTANTE!):**
```bash
bundle exec rake solid_queue:start
```

## Usar el Tracking

### 1. Acceder a la Web

```
http://localhost:3000/tracking
```

### 2. Iniciar Tracking

1. Selecciona una parada de la lista
2. Ingresa las líneas a monitorear (ej: `147, 148, 149`)
3. (Opcional) Ingresa IDs de variantes
4. Click "Iniciar Tracking"

### 3. Ver Dashboard

El dashboard muestra en tiempo real:
- 🚌 Buses acercándose
- 📏 Distancia a la parada
- 🏃 Velocidad promedio calculada
- ⏱️ Tiempo estimado de llegada (ETA)
- 🎯 Estado (Llegando, Muy cerca, etc.)

**Auto-refresh**: La página se actualiza cada 10 segundos automáticamente

## Comandos Útiles

### Ver estado del tracking
```bash
rails tracking:status
```

### Limpiar sistema (si algo se atascó)
```bash
rails tracking:cleanup
```

### Detener tracking de una parada
```bash
rails tracking:stop[STOP_ID]
# Ejemplo: rails tracking:stop[3]
```

### Ver jobs en cola
```bash
rails runner "puts SolidQueue::Job.count"
rails runner "puts SolidQueue::ClaimedExecution.count"
```

## Troubleshooting

### ❌ "Jobs no se procesan"

**Problema**: El worker no está corriendo

**Solución**: Asegúrate de tener el worker corriendo:
```bash
# Verifica si está corriendo
rails runner "puts SolidQueue::Process.count"

# Si es 0, inicia el worker
bundle exec rake solid_queue:start
```

### ❌ "Web no responde al iniciar tracking"

**Problema**: Configuración incorrecta de Active Job

**Solución**: Verifica `config/environments/development.rb`:
```ruby
config.active_job.queue_adapter = :solid_queue
```

### ❌ "Jobs atascados"

**Problema**: Worker se cayó con jobs en proceso

**Solución**: Limpia el sistema:
```bash
rails tracking:cleanup
```

### ❌ "No aparecen buses en el dashboard"

**Checklist**:
1. ✅ ¿El worker está corriendo?
   ```bash
   rails runner "puts SolidQueue::Process.count"
   ```

2. ✅ ¿Hay trackings activos?
   ```bash
   rails tracking:status
   ```

3. ✅ ¿Las líneas pasan por esa parada?
   - Verifica las líneas seleccionadas

4. ✅ ¿Hay buses circulando?
   - Verifica horario y día de la semana

5. ✅ ¿Hay errores en los logs?
   ```bash
   tail -f log/development.log
   ```

## Arquitectura Rápida

```
Usuario Web ──> Controller ──> Encola Job ──> Worker ──> API STM
                                                   │
                                                   ▼
Dashboard <── BusTracking <── BusPosition <── Procesa datos
   (auto-refresh 10s)         (modelo)          (distancia, velocidad)
```

## Flujo de Datos

1. **Inicio**: Usuario selecciona parada y líneas
2. **Job**: Se encola `TrackBusesJob`
3. **Worker**: Ejecuta job cada 15 segundos
4. **API**: Consulta posiciones de buses
5. **Procesamiento**: 
   - Calcula distancias
   - Calcula velocidad promedio (ignora API)
   - Detecta si el bus pasó
   - Guarda historial (últimas 30 posiciones)
6. **Dashboard**: Muestra datos actualizados

## Ejemplos de Uso

### Tracking simple
```
Parada: 1478
Líneas: 147, 148, 149
```

### Tracking con variantes específicas
```
Parada: 1478
Líneas: 147, 148
Variantes: 4420, 4424, 4426
```

### Desde consola (modo síncrono - BLOQUEANTE)
```bash
STOP_ID=1478 LINES='147,148,149' rails tracking:start
```
⚠️ Esto bloqueará la terminal actual

## Features Importantes

### ✨ Velocidad Real
El sistema **ignora** el campo `speed` de la API (es incorrecto) y calcula la velocidad real basándose en cambios de distancia y tiempo entre posiciones.

### ✨ Detección de Paso
Si el bus se aleja en las últimas 5 mediciones consecutivas, el sistema detecta que ya pasó por la parada y deja de mostrarlo en el dashboard (pero sigue trackeándolo).

### ✨ ETA Inteligente
Calcula tiempo estimado de llegada usando:
- Velocidad promedio real
- Distancia actual
- Solo para buses acercándose

### ✨ Auto-reencolar
Los jobs se re-encolan automáticamente cada 15 segundos, evitando bloquear el worker.

## Próximos Pasos

1. ✅ Inicia el sistema: `./bin/dev-with-workers`
2. ✅ Accede a: `http://localhost:3000/tracking`
3. ✅ Inicia tracking de tu parada favorita
4. ✅ Observa el dashboard actualizarse automáticamente
5. 🎉 ¡Disfruta!

## Más Información

- Ver: `TRACKING_README.md` - Documentación completa
- Ver: `WORKERS_SETUP.md` - Configuración de workers
- Ver: `TRACKING_IMPROVEMENTS.md` - Mejoras implementadas

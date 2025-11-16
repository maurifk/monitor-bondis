# Configuración de Workers en Background

## ¿Por qué se necesita un worker separado?

El sistema de tracking consulta la API cada 15 segundos en un loop infinito. Si esto se ejecuta en el mismo hilo que el servidor web, **bloquea todas las requests HTTP** y la aplicación deja de responder.

**Solución**: Usar **Solid Queue** (sistema de jobs de Rails 8) para ejecutar el tracking en un proceso separado.

## Arquitectura

```
┌─────────────────┐     ┌─────────────────┐     ┌──────────────────┐
│   Web Server    │     │  Solid Queue    │     │  TrackBusesJob   │
│   (Puma)        │────>│   (Worker)      │────>│  (Background)    │
│                 │     │                 │     │                  │
│  - HTTP requests│     │  - Procesa jobs │     │  - Loop infinito │
│  - Sirve views  │     │  -Async        │     │  - API calls     │
│  - Controllers  │     │  - Base de datos│     │  - Cada 15s      │
└─────────────────┘     └─────────────────┘     └──────────────────┘
```

## Configuración Realizada

### 1. Gemfile
Ya incluye `solid_queue` (viene con Rails 8):
```ruby
gem "solid_queue"
```

### 2. Development Environment
`config/environments/development.rb`:
```ruby
config.active_job.queue_adapter = :solid_queue
```

### 3. Procfile.dev
Actualizado para incluir el worker:
```
web: bin/rails server
css: bin/rails tailwindcss:watch
jobs: bundle exec rake solid_queue:start
```

### 4. Script de inicio
`bin/dev-with-workers` - Inicia todo junto

## Cómo Usar

### Iniciar TODO (Web + CSS + Worker)

```bash
# Opción más fácil
./bin/dev-with-workers

# O con foreman
foreman start -f Procfile.dev
```

Verás algo como:
```
11:30:45 web.1    | => Booting Puma
11:30:45 css.1    | Rebuilding...
11:30:45 jobs.1   | Solid Queue starting...
11:30:46 web.1    | * Listening on http://127.0.0.1:3000
11:30:46 jobs.1   | Solid Queue ready
```

### Iniciar Manualmente (3 terminales)

**Terminal 1 - Web:**
```bash
rails server
```

**Terminal 2 - CSS:**
```bash
rails tailwindcss:watch
```

**Terminal 3 - Worker:**
```bash
bundle exec rake solid_queue:start
```

### Verificar que el Worker está funcionando

```bash
# Ver jobs encolados
rails runner "puts SolidQueue::Job.count"

# Ver jobs en proceso
rails runner "puts SolidQueue::ClaimedExecution.count"

# Verificar logs
tail -f log/development.log
```

## Flujo de Trabajo

### 1. Usuario inicia tracking desde web

```ruby
# TrackingController#start_tracking
TrackBusesJob.perform_later(stop_id, lines, variants)
# ← Retorna inmediatamente, web sigue respondiendo
```

### 2. Solid Queue recibe el job

- Job se guarda en la base de datos (`solid_queue_jobs` table)
- Estado inicial: `queued`

### 3. Worker procesa el job

```ruby
# TrackBusesJob#perform (ejecuta UNA iteración)
buses_data = tracker.fetch_buses_for_lines(lines)
buses_data.each { |bus| tracker.process_bus_data(bus) }

# Se re-encola a sí mismo para ejecutar en 15 segundos
TrackBusesJob.set(wait: 15.seconds).perform_later(stop_id, lines, variants)
```

### 4. Job se auto-reencola

- Cada iteración del job:
  1. Consulta la API
  2. Procesa los buses
  3. Se programa a sí mismo para ejecutar nuevamente en 15 segundos
  4. **Termina** (libera el worker)
  
- El tracking continúa hasta que:
  - Se llama a `stop_tracking` desde web (marca trackings como inactivos)
  - No hay trackings activos en los últimos 5 minutos
  - Error no recuperable (después de varios reintentos)

**Ventaja**: El worker no se bloquea, puede procesar otros jobs entre iteraciones

## Tablas de Base de Datos

Solid Queue crea estas tablas automáticamente:

- `solid_queue_jobs` - Jobs encolados
- `solid_queue_scheduled_executions` - Jobs programados
- `solid_queue_ready_executions` - Listos para ejecutar
- `solid_queue_claimed_executions` - En ejecución
- `solid_queue_failed_executions` - Fallidos
- `solid_queue_blocked_executions` - Bloqueados
- `solid_queue_pauses` - Control de pausas
- `solid_queue_processes` - Workers activos
- `solid_queue_semaphores` - Control de concurrencia

## Comandos Útiles

### Iniciar worker
```bash
bundle exec rake solid_queue:start
```

### Ver estado de jobs
```bash
# Desde Rails console
rails c

# Jobs encolados
SolidQueue::Job.count

# Jobs activos
SolidQueue::ClaimedExecution.count

# Jobs fallidos
SolidQueue::FailedExecution.all

# Ver último job
SolidQueue::Job.last.inspect
```

### Limpiar jobs antiguos
```bash
rails runner "SolidQueue::Job.where('created_at < ?', 1.day.ago).delete_all"
```

## Troubleshooting

### "Job no se ejecuta"

**Causa**: Worker no está corriendo

**Solución**:
```bash
# Verifica si hay workers activos
rails runner "puts SolidQueue::Process.count"

# Si es 0, inicia el worker
bundle exec rake solid_queue:start
```

### "Web se congela al iniciar tracking"

**Causa**: No configuraste `config.active_job.queue_adapter`

**Solución**:
```ruby
# config/environments/development.rb
config.active_job.queue_adapter = :solid_queue
```

### "Muchos jobs acumulados"

**Causa**: Worker se cayó y hay jobs pendientes

**Solución**:
```bash
# Ver jobs
rails runner "puts SolidQueue::Job.all.to_yaml"

# Eliminar todos los jobs (CUIDADO!)
rails runner "SolidQueue::Job.delete_all"
```

### "Worker consume mucha memoria"

**Causa**: Muchos trackings activos simultáneos

**Solución**:
- Limita trackings concurrentes
- Detén trackings inactivos regularmente
- Reinicia el worker periódicamente

## Para Producción

### 1. Configurar número de workers

`config/queue.yml`:
```yaml
production:
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: default
      threads: 3
      processes: 2
      polling_interval: 0.1
```

### 2. Usar supervisor

**Systemd** (Linux):
```ini
# /etc/systemd/system/bus-tracker-worker.service
[Unit]
Description=Bus Tracker Worker
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/var/www/bus-tracker
ExecStart=/usr/local/bin/bundle exec rake solid_queue:start
Restart=always

[Install]
WantedBy=multi-user.target
```

**Iniciar**:
```bash
sudo systemctl start bus-tracker-worker
sudo systemctl enable bus-tracker-worker
```

### 3. Monitoreo

Puedes agregar métricas:
```ruby
# config/initializers/solid_queue_monitoring.rb
ActiveSupport::Notifications.subscribe("enqueue.active_job") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  Rails.logger.info "Job enqueued: #{event.payload[:job].class.name}"
end
```

## Resumen

✅ **Web y Worker separados** - Web responde rápido  
✅ **Solid Queue** - Sistema nativo de Rails 8  
✅ **Fácil de usar** - Un comando inicia todo  
✅ **Escalable** - Agrega más workers si es necesario  
✅ **Robusto** - Jobs persisten en DB, se recuperan de errores  

**Comando para recordar**: `./bin/dev-with-workers` 🚀

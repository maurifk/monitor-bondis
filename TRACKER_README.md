# Sistema de Tracking de Bondis

Sistema para monitorear y registrar el paso de bondis (autobuses) por paradas específicas en Montevideo.

## Estructura del Sistema

### Base de Datos (Rails)

El proyecto usa PostgreSQL con migraciones de Rails:

- **Tabla `bus_stops`**: Información de las paradas
  - `busstop_id`: ID de la parada (de la API de STM)
  - `street1`, `street2`: Calles que definen la parada
  - `latitude`, `longitude`: Coordenadas geográficas
  - Índices en coordenadas y busstop_id

- **Tabla `bus_passages`**: Registro de pasadas de bondis
  - `bus_stop_id`: Referencia a la parada
  - `line`: Línea de bondi
  - `destination`: Destino del bondi
  - `bus_code`: Código/matrícula del bondi
  - `bus_latitude`, `bus_longitude`: Coordenadas del bondi
  - `detected_at`: Fecha y hora de detección
  - `eta_minutes`: Tiempo estimado de llegada en minutos
  - Índices en parada+fecha, línea, y fecha

### Modelos Rails

En `bus-tracker/app/models/`:

- `bus_stop.rb`: Modelo ActiveRecord para paradas
- `bus_passage.rb`: Modelo ActiveRecord para pasadas

### Modelos Python (SQLAlchemy)

En `models.py`:

- Clase `BusStop`: Mapeo ORM de la tabla bus_stops
- Clase `BusPassage`: Mapeo ORM de la tabla bus_passages
- Funciones helper para conexión a la base de datos

## Scripts de Python

### 1. `tracker.py` - Monitoreo y Registro

Script principal que monitorea una parada y registra las pasadas en la base de datos.

**Uso:**
```bash
uv run python tracker.py
```

El script:
1. Solicita el ID de la parada a monitorear
2. Configura el intervalo de consulta (default 30 segundos)
3. Consulta la API periódicamente
4. Registra cada pasada en la base de datos
5. Muestra información en tiempo real

**Ejemplo:**
```
Ingresa el ID de la parada a monitorear: 546
Intervalo de consulta en segundos (default 30): 15

==========================================================
  MONITOREANDO PARADA 546
  CORUÑA y GRAL JULIO AMADEO ROLETTI
  Intervalo: 15 segundos
==========================================================

✓ Registrado: Línea 21     → TERMINAL COLON        | ETA: 5 min
✓ Registrado: Línea D10    → MALVIN               | ETA: 12 min

  Total registrado: 2 buses
  Próxima consulta en 15s...
```

### 2. `query_passages.py` - Consulta de Datos

Script interactivo para consultar los datos registrados.

**Uso:**
```bash
uv run python query_passages.py
```

**Opciones del menú:**

1. **Listar paradas monitoreadas**
   - Muestra todas las paradas con registros
   - Cantidad total de pasadas por parada
   - Fecha de última pasada

2. **Ver estadísticas de una línea**
   - Total de pasadas en un período
   - Pasadas por día
   - Últimas 10 pasadas
   - Puede filtrar por parada específica

3. **Ver pasadas de hoy en una parada**
   - Todas las pasadas del día actual
   - Ordenadas por hora
   - Con información de línea, destino y ETA

### 3. `main.py` - Monitor en Tiempo Real (Sin DB)

Script original que solo muestra buses en tiempo real sin guardar datos.

**Uso:**
```bash
uv run python main.py
```

## Configuración

### 1. Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto:

```env
CLIENT_ID=tu_client_id_aqui
CLIENT_SECRET=tu_client_secret_aqui
```

Obtén tus credenciales en: https://www.montevideo.gub.uy/aplicacionesWeb/api

### 2. Base de Datos

La configuración está en `bus-tracker/config/database.yml`:

**Development:**
- Database: `bus_tracker_development`
- Host: localhost
- Puerto: 5432 (default PostgreSQL)

**Para cambiar la configuración en Python:**

En `models.py`, modifica la función `get_db_engine()`:

```python
def get_db_engine(database_url=None):
    if database_url is None:
        database_url = os.getenv(
            "DATABASE_URL", 
            "postgresql://usuario:password@localhost/bus_tracker_development"
        )
    engine = create_engine(database_url, echo=False)
    return engine
```

### 3. Ejecutar Migraciones

```bash
cd bus-tracker
bin/rails db:migrate
```

### 4. Instalar Dependencias Python

```bash
# Con uv (recomendado)
uv add sqlalchemy psycopg2-binary requests python-dotenv

# O con pip
pip install sqlalchemy psycopg2-binary requests python-dotenv
```

## Flujo de Trabajo Típico

### Primer uso

1. Configurar credenciales en `.env`
2. Ejecutar migraciones Rails
3. Ejecutar `tracker.py` para comenzar a registrar datos

### Monitoreo continuo

```bash
# Terminal 1: Monitorear parada 546
uv run python tracker.py
> 546
> 30

# Terminal 2: Monitorear parada 547  
uv run python tracker.py
> 547
> 30
```

### Consulta de datos

```bash
uv run python query_passages.py
# Usar el menú interactivo para explorar los datos
```

## Análisis de Datos

Los datos en la base de datos pueden ser analizados con:

- **Rails Console**: `bin/rails console`
  ```ruby
  # Ver estadísticas
  BusStop.first.bus_passages.count
  BusPassage.where(line: "21").today.count
  ```

- **Python**:
  ```python
  from models import get_session, BusStop, BusPassage
  session = get_session()
  
  # Contar pasadas por línea
  from sqlalchemy import func
  session.query(BusPassage.line, func.count(BusPassage.id)).\
      group_by(BusPassage.line).all()
  ```

- **SQL directo**: Conectarse con psql, DBeaver, pgAdmin, etc.

## Próximas Mejoras

- [ ] Detección de proximidad (cuando el bondi está muy cerca)
- [ ] Alertas/notificaciones cuando llegue una línea específica
- [ ] Dashboard web con visualizaciones
- [ ] Análisis de patrones y horarios típicos
- [ ] API REST para acceso a los datos
- [ ] Cálculo de puntualidad y retrasos

## Estructura de Archivos

```
monitor-bondis/
├── bus-tracker/                    # Proyecto Rails
│   ├── app/models/
│   │   ├── bus_stop.rb
│   │   └── bus_passage.rb
│   ├── db/migrate/
│   │   ├── TIMESTAMP_create_bus_stops.rb
│   │   └── TIMESTAMP_create_bus_passages.rb
│   └── config/database.yml
├── models.py                       # Modelos SQLAlchemy
├── tracker.py                      # Script de monitoreo
├── query_passages.py               # Script de consultas
├── main.py                         # Monitor simple (sin DB)
├── .env                            # Credenciales (no commitear!)
└── TRACKER_README.md              # Esta documentación
```

## Notas Importantes

- Los scripts usan la hora UTC (`datetime.utcnow()`)
- El intervalo mínimo recomendado es 15 segundos para no sobrecargar la API
- Los datos de `eta_minutes` pueden ser `null` si el bondi no reporta ETA
- Las coordenadas usan el formato GeoJSON [longitud, latitud]

## Soporte

Para más información sobre la API de STM:
- Documentación: https://www.montevideo.gub.uy/aplicacionesWeb/api
- Endpoint de paradas: `/api/transportepublico/buses/busstops`
- Endpoint de buses próximos: `/api/transportepublico/buses/busstops/{id}/upcomingbuses`

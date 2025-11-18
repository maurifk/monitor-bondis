# 🚌 Monitor de Bondis - Montevideo

Aplicación Rails para visualizar en tiempo real la ubicación de los buses de una línea específica en un mapa interactivo de Montevideo.

## Características

- 🔐 Autenticación OAuth2 con la API de STM (reutiliza la lógica del script Python)
- 🗺️ Visualización en mapa interactivo usando Leaflet
- 🔄 Actualización automática cada 15 segundos
- 📱 Diseño responsive con Tailwind CSS
- 🎯 Filtrado por línea de bus
- 🚏 Búsqueda de paradas y visualización de ómnibus aproximándose
- ⏱️ Estimación de tiempos de llegada usando OSRM (rutas reales)
- 📍 Cálculo inteligente de próxima parada por segmentos

## Requisitos

- Ruby 3.3.2 o superior
- PostgreSQL (o cambiar a SQLite3 en `config/database.yml`)
- Credenciales de la API de STM (CLIENT_ID y CLIENT_SECRET)
- **Docker Desktop** (opcional, para servidor OSRM local)

## Instalación

1. **Clonar o navegar al directorio del proyecto:**
   ```bash
   cd bus-tracker
   ```

2. **Instalar dependencias:**
   ```bash
   bundle install
   ```

3. **Configurar variables de entorno:**
   
   Crea un archivo `.env` en la raíz del proyecto:
   ```bash
   cp .env.example .env
   ```
   
   Edita el archivo `.env` y agrega tus credenciales:
   ```env
   CLIENT_ID=tu_client_id
   CLIENT_SECRET=tu_client_secret
   OSRM_URL=http://localhost:5555
   ```
   
   Puedes obtener tus credenciales en: https://www.montevideo.gub.uy/aplicacionesWeb/api

4. **Configurar la base de datos:**
   ```bash
   rails db:create
   rails db:migrate
   ```

5. **(Opcional) Configurar servidor OSRM local:**
   
   Para mejor rendimiento y sin límites de consultas, configura un servidor OSRM local:
   
   ```bash
   # Desde el directorio raíz del proyecto (no bus-tracker/)
   cd ..
   ./setup-osrm.sh    # Configuración inicial (solo una vez)
   ./start-osrm.sh    # Inicia el servidor OSRM
   ```
   
   Ver instrucciones completas en: [OSRM_SETUP.md](../OSRM_SETUP.md)
   
   Si prefieres usar el servidor público, cambia en `.env`:
   ```env
   OSRM_URL=https://router.project-osrm.org
   ```

6. **Iniciar el servidor Rails:**
   ```bash
   rails server
   ```

7. **Abrir en el navegador:**
   ```
   http://localhost:3000
   ```

## Uso

### Buscar por Línea

1. Ingresa el número de línea que deseas monitorear (por ejemplo: 21, 526, D10, etc.)
2. Haz clic en "Buscar" o presiona Enter
3. Los buses aparecerán como marcadores azules en el mapa
4. Cada bus muestra su **próxima parada** estimada
5. Haz clic en un marcador para ver detalles del bus
6. Haz clic en una tarjeta de bus en la lista para centrar el mapa en ese bus
7. El mapa se actualiza automáticamente cada 15 segundos
8. Usa el botón "🔄 Actualizar" para actualizar manualmente

### Buscar por Parada

1. Ve a "Buscar Parada" en el menú
2. Busca una parada por nombre de calle o ID
3. Selecciona la parada deseada
4. Verás todos los ómnibus que van hacia esa parada con:
   - ⏱️ **Tiempo estimado de llegada** (en minutos)
   - 🕐 Hora estimada de llegada
   - 📏 Distancia total a recorrer
   - 📍 Próxima parada del ómnibus
5. Los ómnibus están ordenados por cercanía (el más próximo primero)

## Estructura del Proyecto

```
bus-tracker/
├── app/
│   ├── controllers/
│   │   └── buses_controller.rb      # Controlador principal
│   ├── services/
│   │   ├── stm_auth_service.rb      # Servicio de autenticación OAuth2
│   │   └── stm_bus_service.rb       # Servicio para consultar buses
│   └── views/
│       └── buses/
│           └── index.html.erb       # Vista principal con el mapa
├── config/
│   └── routes.rb                     # Rutas de la aplicación
└── .env                              # Variables de entorno (no versionado)
```

## API Endpoints Utilizados

- **Autenticación:** `POST https://mvdapi-auth.montevideo.gub.uy/token`
- **Buses por línea:** `GET https://api.montevideo.gub.uy/api/transportepublico/buses?lines={line}`

## Tecnologías Utilizadas

- **Rails 8.0** - Framework web
- **Leaflet** - Biblioteca de mapas interactivos
- **Tailwind CSS** - Framework CSS
- **HTTParty** - Cliente HTTP
- **dotenv-rails** - Manejo de variables de entorno
- **OSRM** - Motor de enrutamiento para cálculo de tiempos de llegada
- **Docker** - Contenedores para servidor OSRM local

## Documentación Adicional

- **[STOPS_FEATURE.md](../STOPS_FEATURE.md)** - Documentación completa de la funcionalidad de paradas
- **[OSRM_SETUP.md](../OSRM_SETUP.md)** - Guía detallada para configurar OSRM local
- **[ARRIVAL_ESTIMATION_EXAMPLE.md](../ARRIVAL_ESTIMATION_EXAMPLE.md)** - Ejemplos de cómo funciona la estimación de tiempos

## Notas

- El token OAuth2 se renueva automáticamente 30 segundos antes de expirar
- Los marcadores se actualizan cada 15 segundos automáticamente
- El mapa se centra automáticamente para mostrar todos los buses visibles
- Los tiempos de llegada se calculan usando rutas reales de calles (no distancia directa)
- El algoritmo de próxima parada usa distancia perpendicular a segmentos para mayor precisión

## Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

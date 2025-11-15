# 🚌 Monitor de Bondis - Montevideo

Aplicación Rails para visualizar en tiempo real la ubicación de los buses de una línea específica en un mapa interactivo de Montevideo.

## Características

- 🔐 Autenticación OAuth2 con la API de STM (reutiliza la lógica del script Python)
- 🗺️ Visualización en mapa interactivo usando Leaflet
- 🔄 Actualización automática cada 15 segundos
- 📱 Diseño responsive con Tailwind CSS
- 🎯 Filtrado por línea de bus

## Requisitos

- Ruby 3.3.2 o superior
- PostgreSQL (o cambiar a SQLite3 en `config/database.yml`)
- Credenciales de la API de STM (CLIENT_ID y CLIENT_SECRET)

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
   ```
   CLIENT_ID=tu_client_id
   CLIENT_SECRET=tu_client_secret
   ```
   
   Puedes obtener tus credenciales en: https://www.montevideo.gub.uy/aplicacionesWeb/api

4. **Configurar la base de datos:**
   ```bash
   rails db:create
   rails db:migrate
   ```

5. **Iniciar el servidor:**
   ```bash
   rails server
   ```

6. **Abrir en el navegador:**
   ```
   http://localhost:3000
   ```

## Uso

1. Ingresa el número de línea que deseas monitorear (por ejemplo: 21, 526, D10, etc.)
2. Haz clic en "Buscar" o presiona Enter
3. Los buses aparecerán como marcadores azules en el mapa
4. Haz clic en un marcador para ver detalles del bus
5. Haz clic en una tarjeta de bus en la lista para centrar el mapa en ese bus
6. El mapa se actualiza automáticamente cada 15 segundos
7. Usa el botón "🔄 Actualizar" para actualizar manualmente

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

## Notas

- El token OAuth2 se renueva automáticamente 30 segundos antes de expirar
- Los marcadores se actualizan cada 15 segundos automáticamente
- El mapa se centra automáticamente para mostrar todos los buses visibles

## Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

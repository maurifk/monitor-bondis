# Configuración del Servidor OSRM Local

## ¿Qué es OSRM?

OSRM (Open Source Routing Machine) es un motor de enrutamiento de código abierto que calcula rutas óptimas entre puntos en un mapa. Lo usamos para estimar tiempos de llegada reales de los ómnibus considerando las calles y rutas reales.

## ¿Por qué usar servidor local?

✅ **Ventajas:**
- Sin límite de consultas
- Menor latencia (respuestas más rápidas)
- Funciona sin conexión a Internet (una vez configurado)
- Datos específicos de Uruguay

❌ **Servidor público:**
- Límites de tasa de consultas
- Mayor latencia
- Requiere conexión a Internet

## Requisitos Previos

1. **Docker Desktop** instalado y corriendo
   - Descarga desde: https://www.docker.com/products/docker-desktop
   - Inicia Docker Desktop antes de continuar

2. **Archivo de mapa de Uruguay** (ya descargado)
   - `uruguay-251117.osm.pbf` (debe estar en el directorio raíz del proyecto)

## Instalación Paso a Paso

### 1. Asegúrate de estar en el directorio correcto

```bash
cd /Users/mauriciofrissdekereki/Documents/monitor-bondis
```

### 2. Verifica que Docker esté corriendo

```bash
docker ps
```

Si ves "Cannot connect to the Docker daemon", inicia Docker Desktop.

### 3. Ejecuta el script de configuración

Este paso procesará el mapa de Uruguay y puede tomar **10-15 minutos** dependiendo de tu máquina:

```bash
./setup-osrm.sh
```

Este script hace lo siguiente:
1. Descarga la imagen Docker de OSRM
2. **Extrae** datos del mapa (`osrm-extract`) - Toma ~5-10 min
3. **Contrae** el grafo para optimizar (`osrm-contract`) - Toma ~5 min

### 4. Inicia el servidor OSRM

```bash
./start-osrm.sh
```

El servidor iniciará en: **http://localhost:5555**

> ℹ️ Usamos el puerto 5555 para evitar conflictos con Rails (puerto 3000)

### 5. Prueba que funcione

En otra terminal:

```bash
curl 'http://localhost:5555/route/v1/driving/-56.1645,-34.9011;-56.1679,-34.9058'
```

Deberías ver una respuesta JSON con la ruta calculada.

## Configuración en la Aplicación

La aplicación ya está configurada para usar el servidor local. Verifica en:

**Archivo:** `bus-tracker/.env`

```env
OSRM_URL=http://localhost:5555
```

## Comandos Útiles

### Iniciar el servidor
```bash
./start-osrm.sh
```

### Detener el servidor
Presiona `Ctrl+C` en la terminal donde está corriendo

### Ver contenedores Docker corriendo
```bash
docker ps
```

### Detener todos los contenedores OSRM
```bash
docker stop $(docker ps -q --filter ancestor=ghcr.io/project-osrm/osrm-backend)
```

## Uso Manual (sin scripts)

Si prefieres ejecutar los comandos manualmente:

```bash
# 1. Descargar imagen
docker pull ghcr.io/project-osrm/osrm-backend:latest

# 2. Extraer datos
docker run -t -v $(pwd):/data ghcr.io/project-osrm/osrm-backend:latest \
    osrm-extract -p /opt/car.lua /data/uruguay-251117.osm.pbf

# 3. Contraer grafo
docker run -t -v $(pwd):/data ghcr.io/project-osrm/osrm-backend:latest \
    osrm-contract /data/uruguay-251117.osrm

# 4. Iniciar servidor
docker run -t -i -p 5555:5000 -v $(pwd):/data \
    ghcr.io/project-osrm/osrm-backend:latest \
    osrm-routed --algorithm mld /data/uruguay-251117.osrm
```

## Archivos Generados

Después de ejecutar `setup-osrm.sh`, verás estos archivos:

- `uruguay-251117.osrm` - Grafo de ruta procesado
- `uruguay-251117.osrm.cells` - Datos de celdas
- `uruguay-251117.osrm.cnbg` - Datos de grafo contraído
- `uruguay-251117.osrm.cnbg_to_ebg` - Mapeo de nodos
- `uruguay-251117.osrm.ebg` - Grafo de aristas
- `uruguay-251117.osrm.ebg_nodes` - Nodos del grafo
- `uruguay-251117.osrm.edges` - Aristas
- `uruguay-251117.osrm.enw` - Pesos de aristas
- `uruguay-251117.osrm.fileIndex` - Índice de archivos
- `uruguay-251117.osrm.geometry` - Geometría de la red
- `uruguay-251117.osrm.icd` - Datos de intersecciones
- `uruguay-251117.osrm.maneuver_overrides` - Sobrescrituras de maniobras
- `uruguay-251117.osrm.mldgr` - Grafo MLD
- `uruguay-251117.osrm.names` - Nombres de calles
- `uruguay-251117.osrm.partition` - Partición del grafo
- `uruguay-251117.osrm.properties` - Propiedades
- `uruguay-251117.osrm.ramIndex` - Índice RAM
- `uruguay-251117.osrm.timestamp` - Timestamp
- `uruguay-251117.osrm.tld` - Datos de nivel superior
- `uruguay-251117.osrm.tls` - Señales de tráfico
- `uruguay-251117.osrm.turn_penalties_index` - Índice de penalizaciones

Estos archivos **no** deben agregarse al repositorio Git (ya están en `.gitignore`).

## Solución de Problemas

### Error: "Cannot connect to the Docker daemon"
**Solución:** Inicia Docker Desktop y espera a que termine de cargar completamente.

### Error: "archivo .osm.pbf no encontrado"
**Solución:** Asegúrate de estar en el directorio correcto:
```bash
cd /Users/mauriciofrissdekereki/Documents/monitor-bondis
ls uruguay-251117.osm.pbf  # Debe existir
```

### El servidor no responde en localhost:5555
**Solución:** 
1. Verifica que el contenedor esté corriendo: `docker ps`
2. Revisa los logs del contenedor: `docker logs <container_id>`
3. Prueba reiniciar el servidor: `Ctrl+C` y luego `./start-osrm.sh`

### Error de memoria durante la extracción/contracción
**Solución:** El archivo de Uruguay es grande. Asegúrate de tener al menos 4GB de RAM disponible para Docker. 

En Docker Desktop: Settings → Resources → Memory (configura al menos 4GB)

### Puerto 5555 ya está en uso
**Solución:** Cambia el puerto en `start-osrm.sh` de `5555` a otro (ej: `5556`) y actualiza también el `.env`:
```env
OSRM_URL=http://localhost:5556
```

## Volver al Servidor Público

Si prefieres usar el servidor público de OSRM, edita `bus-tracker/.env`:

```env
OSRM_URL=https://router.project-osrm.org
```

**Nota:** El servidor público puede tener límites de tasa y no tiene datos optimizados para Uruguay.

## Referencias

- OSRM Backend: https://github.com/Project-OSRM/osrm-backend
- OSRM Docker: https://github.com/Project-OSRM/osrm-backend/wiki/Docker-Recipes
- Documentación API: http://project-osrm.org/docs/v5.24.0/api/

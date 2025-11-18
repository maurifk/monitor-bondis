# 🎯 Próximos Pasos para Usar OSRM Local

## Estado Actual
✅ Todo el código está implementado y listo  
✅ Scripts de configuración creados  
✅ Documentación completa  
⏳ Falta: Ejecutar la configuración de OSRM

## Pasos a Seguir

### 1️⃣ Inicia Docker Desktop
Antes que nada, asegúrate de que Docker Desktop esté corriendo:

```bash
# Verifica que Docker esté corriendo
docker ps
```

Si ves un error, inicia Docker Desktop desde tus aplicaciones.

---

### 2️⃣ Procesa el Mapa de Uruguay (Solo Una Vez)

Este paso toma **10-15 minutos**. Procesa el archivo `uruguay-251117.osm.pbf` y genera los archivos necesarios para OSRM.

```bash
cd /Users/mauriciofrissdekereki/Documents/monitor-bondis
./setup-osrm.sh
```

**Lo que verás:**
```
🚀 Configurando OSRM Server Local
==================================
✓ Docker está corriendo
✓ Archivo OSM encontrado: uruguay-251117.osm.pbf

📦 Descargando imagen de OSRM...
🗺️  Extrayendo datos del mapa (esto puede tomar varios minutos)...
✓ Extracción completada exitosamente
📊 Contrayendo el grafo (optimización)...
✓ Contracción completada exitosamente

🎉 ¡Configuración completada!
```

**Nota:** Esto solo se hace UNA VEZ. Los archivos generados se reutilizan después.

---

### 3️⃣ Inicia el Servidor OSRM

**⚠️ IMPORTANTE:** Asegúrate de que Docker Desktop esté corriendo antes de continuar.

```bash
./start-osrm.sh
```

**Lo que verás:**
```
🚀 Iniciando servidor OSRM local...
==================================
✓ Docker está corriendo
✓ Archivos OSRM encontrados

🌐 Iniciando servidor en http://localhost:5555

[osrm-routed] starting up engines, v5.27.1
[osrm-routed] Threads: 8
[osrm-routed] IP address: 0.0.0.0
[osrm-routed] IP port: 5000
[osrm-routed] http 1.1 compression handled by zlib version 1.2.11
[osrm-routed] running and waiting for requests
```

**⚠️ IMPORTANTE:** Deja esta terminal abierta corriendo el servidor.

---

### 4️⃣ Prueba que OSRM Funcione (En Otra Terminal)

Abre una NUEVA terminal y ejecuta:

```bash
cd /Users/mauriciofrissdekereki/Documents/monitor-bondis
./test-osrm.sh
```

**Resultado esperado:**
```
🧪 Probando servidor OSRM...
==============================

Servidor: http://localhost:5555

Probando ruta: Plaza Independencia → Obelisco

✅ Servidor OSRM funcionando correctamente

📊 Resultado:
   Duración: 1.6 minutos (95.3 segundos)
   Distancia: 0.87 km (871.8 metros)

🎉 ¡Todo OK!
```

---

### 5️⃣ Inicia la Aplicación Rails (En Otra Terminal)

Con OSRM corriendo, inicia Rails:

```bash
cd /Users/mauriciofrissdekereki/Documents/monitor-bondis/bus-tracker
rails server
```

---

### 6️⃣ Prueba la Aplicación

Abre tu navegador en: **http://localhost:3000**

#### Opción 1: Buscar por Línea
1. Ve a la página principal
2. Busca una línea (ej: "21")
3. Verás cada bus con su próxima parada

#### Opción 2: Buscar por Parada ⏱️ (¡Con tiempos!)
1. Click en "Buscar Parada" en el menú
2. Busca "18 de julio" o cualquier calle
3. Selecciona una parada
4. 🎉 **Verás los buses aproximándose con:**
   - ⏱️ Tiempo estimado: "5 min"
   - 🕐 Hora estimada: "14:48"
   - 📏 Distancia: "2.3 km"

---

## 🔄 Día a Día

### Para trabajar normalmente:

**Terminal 1 - OSRM:**
```bash
cd /Users/mauriciofrissdekereki/Documents/monitor-bondis
./start-osrm.sh
```

**Terminal 2 - Rails:**
```bash
cd /Users/mauriciofrissdekereki/Documents/monitor-bondis/bus-tracker
rails server
```

**Navegador:**
```
http://localhost:3000
```

### Para detener:
- En cada terminal presiona `Ctrl+C`

---

## 🆘 Si Algo Sale Mal

### "Cannot connect to Docker daemon"
→ Inicia Docker Desktop

### "Error: archivo .osm.pbf no encontrado"
→ Asegúrate de estar en el directorio correcto:
```bash
cd /Users/mauriciofrissdekereki/Documents/monitor-bondis
ls uruguay-251117.osm.pbf  # Debe existir
```

### "puerto 5555 ya en uso"
→ Mata el proceso anterior:
```bash
lsof -ti:5555 | xargs kill -9
```

### El servidor OSRM se cayó
→ Vuelve a ejecutar:
```bash
./start-osrm.sh
```

### No veo tiempos en la aplicación
1. Verifica que OSRM esté corriendo: `./test-osrm.sh`
2. Verifica el `.env`: debe tener `OSRM_URL=http://localhost:5555`
3. Reinicia Rails

---

## 🎯 Alternativa: Usar Servidor Público

Si no quieres configurar OSRM local, puedes usar el servidor público:

**Edita** `bus-tracker/.env`:
```env
OSRM_URL=https://router.project-osrm.org
```

**Reinicia Rails:**
```bash
# Ctrl+C en la terminal de Rails, luego:
rails server
```

**⚠️ Limitaciones del servidor público:**
- Límite de consultas
- Más lento (~500ms vs ~50ms)
- Requiere Internet

---

## 📚 Documentación Completa

- **[QUICK_START.md](QUICK_START.md)** - Guía rápida
- **[OSRM_SETUP.md](OSRM_SETUP.md)** - Setup detallado
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Resumen técnico
- **[ARRIVAL_ESTIMATION_EXAMPLE.md](ARRIVAL_ESTIMATION_EXAMPLE.md)** - Cómo funciona

---

## ✅ Checklist Final

Antes de empezar, verifica:

- [ ] Docker Desktop instalado y corriendo
- [ ] Archivo `uruguay-251117.osm.pbf` en el directorio raíz
- [ ] Scripts tienen permisos de ejecución (ya configurado)
- [ ] Tienes ~4GB de RAM disponible para Docker
- [ ] Puerto 5555 está libre

---

## 🎉 ¡Listo para Empezar!

Ejecuta el paso #2 (`./setup-osrm.sh`) y sigue desde ahí.

¿Preguntas? Revisa la documentación o los logs de Docker.

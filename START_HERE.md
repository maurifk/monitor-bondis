# 🎯 ¡EMPIEZA AQUÍ! - Servidor OSRM Local

## ✅ Setup Completado

El procesamiento del mapa de Uruguay se completó exitosamente:
- ✅ Imagen Docker descargada
- ✅ Mapa extraído (2.5 segundos)
- ✅ Grafo contraído (132 segundos)
- ✅ 24 archivos generados (~200 MB)

## 🚀 Cómo Usar (3 Pasos Simples)

### 1️⃣ Abre Docker Desktop

**MUY IMPORTANTE:** Docker Desktop debe estar corriendo.

Abre la aplicación Docker Desktop desde tus aplicaciones y espera a que termine de iniciar (el ícono debe dejar de parpadear).

---

### 2️⃣ Inicia el Servidor OSRM

Abre una terminal y ejecuta:

```bash
cd /Users/mauriciofrissdekereki/Documents/monitor-bondis
./start-osrm.sh
```

**Verás algo como:**
```
🚀 Iniciando servidor OSRM local...
✓ Docker está corriendo
✓ Archivos OSRM encontrados
🌐 Iniciando servidor en http://localhost:5555

[osrm-routed] starting up engines, v5.27.1
[osrm-routed] running and waiting for requests
```

✅ **¡Perfecto!** Deja esta terminal abierta.

---

### 3️⃣ Prueba que Funcione

Abre una **NUEVA terminal** y ejecuta:

```bash
cd /Users/mauriciofrissdekereki/Documents/monitor-bondis
./test-osrm.sh
```

**Deberías ver:**
```
✅ Servidor OSRM funcionando correctamente

📊 Resultado:
   Duración: 1.6 minutos (95.3 segundos)
   Distancia: 0.87 km (871.8 metros)

🎉 ¡Todo OK!
```

---

## 🎉 ¡Listo! Ahora Usa la Aplicación

### Inicia Rails (en otra terminal nueva)

```bash
cd /Users/mauriciofrissdekereki/Documents/monitor-bondis/bus-tracker
rails server
```

### Abre el Navegador

Ve a: **http://localhost:3000**

1. Click en "**Buscar Parada**"
2. Busca una parada (ej: "18 de julio")
3. Selecciona la parada
4. 🎉 **Verás los tiempos de llegada:**
   - ⏱️ "5 min"
   - 🕐 "14:48"
   - 📏 "2.3 km"

---

## 🔄 Uso Diario

Cada vez que trabajes:

**Terminal 1:**
```bash
./start-osrm.sh
```

**Terminal 2:**
```bash
cd bus-tracker && rails server
```

**Navegador:**
```
http://localhost:3000
```

Para detener: `Ctrl+C` en cada terminal

---

## 🆘 Problemas Comunes

### "Cannot connect to Docker daemon"
→ Inicia Docker Desktop y espera 30 segundos

### "puerto 5555 ya en uso"  
→ Hay un servidor OSRM corriendo ya
```bash
lsof -ti:5555 | xargs kill -9
```

### No veo tiempos en la app
1. Verifica OSRM: `./test-osrm.sh`
2. Verifica `.env`: `OSRM_URL=http://localhost:5555`
3. Reinicia Rails

---

## 📚 Documentación

- **Guía completa:** [QUICK_START.md](QUICK_START.md)
- **Setup OSRM:** [OSRM_SETUP.md](OSRM_SETUP.md)
- **Cómo funciona:** [ARRIVAL_ESTIMATION_EXAMPLE.md](ARRIVAL_ESTIMATION_EXAMPLE.md)

---

## ✨ ¿Qué Hace Esto?

Calcula **tiempos reales de llegada** de ómnibus usando:
- 🗺️ Rutas reales de calles (no línea recta)
- 🚏 Todas las paradas intermedias
- ⚡ Servidor local = sin límites + rápido

---

**¡Disfruta tu aplicación de estimación de llegadas!** 🚌⏱️

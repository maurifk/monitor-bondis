# 🚀 Guía Rápida - Monitor de Bondis con OSRM

## ¿Qué es esto?

Una aplicación Rails que muestra ómnibus en tiempo real y estima **cuándo van a llegar** a cada parada usando rutas reales de calles.

## 🎯 Inicio Rápido (5 minutos)

### 1. Inicia Docker Desktop
Asegúrate de que Docker Desktop esté corriendo.

### 2. Configura OSRM (solo la primera vez)
```bash
cd /Users/mauriciofrissdekereki/Documents/monitor-bondis
./setup-osrm.sh
```
⏱️ Toma 10-15 minutos. Ve a tomar un café ☕

### 3. Inicia el servidor OSRM
```bash
./start-osrm.sh
```
✅ Deja esta terminal abierta corriendo

### 4. Prueba OSRM (en otra terminal)
```bash
./test-osrm.sh
```
Deberías ver: `✅ Servidor OSRM funcionando correctamente`

### 5. Inicia Rails (en otra terminal)
```bash
cd bus-tracker
rails server
```

### 6. Abre en el navegador
```
http://localhost:3000
```

## 📋 Uso

### Opción A: Buscar por Línea
1. Escribe un número de línea (ej: "21")
2. Ve los buses en el mapa
3. Cada bus muestra su próxima parada

### Opción B: Buscar por Parada (¡Con tiempos!)
1. Click en "Buscar Parada"
2. Busca una parada (ej: "18 de julio")
3. Selecciona la parada
4. 🎉 Ve todos los buses que vienen con:
   - **Tiempo en minutos** (ej: "5 min")
   - Hora estimada (ej: "14:48")
   - Distancia (ej: "2.3 km")

## 🔧 Comandos Útiles

### Iniciar servidor OSRM
```bash
cd /Users/mauriciofrissdekereki/Documents/monitor-bondis
./start-osrm.sh
```

### Probar OSRM
```bash
./test-osrm.sh
```

### Ver logs de Docker
```bash
docker ps
docker logs <container_id>
```

### Detener OSRM
Presiona `Ctrl+C` en la terminal donde está corriendo

## 🆘 Solución Rápida de Problemas

### "Cannot connect to Docker daemon"
→ Inicia Docker Desktop

### "puerto 5555 ya en uso"
→ Detén el servidor OSRM anterior: busca el proceso y mátalo
```bash
lsof -ti:5555 | xargs kill -9
```

### "Server no respondió"
→ Asegúrate de que `./start-osrm.sh` esté corriendo

### Quiero usar el servidor público de OSRM
→ Edita `bus-tracker/.env`:
```env
OSRM_URL=https://router.project-osrm.org
```

## 📚 Más Información

- **Setup detallado OSRM:** [OSRM_SETUP.md](OSRM_SETUP.md)
- **Documentación completa:** [STOPS_FEATURE.md](STOPS_FEATURE.md)
- **Cómo funciona:** [ARRIVAL_ESTIMATION_EXAMPLE.md](ARRIVAL_ESTIMATION_EXAMPLE.md)

## 🎯 Arquitectura Simplificada

```
Usuario busca parada
    ↓
Rails consulta API STM → Obtiene buses en tiempo real
    ↓
Para cada bus:
  1. ¿Dónde está? (coordenadas GPS)
  2. ¿Cuál es su próxima parada? (algoritmo por segmentos)
  3. ¿Va hacia mi parada? (verifica orden de paradas)
  4. Si SÍ → Consulta OSRM con ruta completa
    ↓
OSRM (local) → Calcula tiempo y distancia real
    ↓
Usuario ve: "Línea 21 → 5 min (14:48) - 2.3 km"
```

## ✨ Características Clave

✅ Tiempos reales basados en rutas de calles (no línea recta)  
✅ Considera todas las paradas intermedias  
✅ Ordenamiento automático por cercanía  
✅ Servidor local = sin límites + más rápido  
✅ Fallback al servidor público si algo falla  

## 🎉 ¡Eso es todo!

Ya tienes un sistema completo de estimación de llegadas de ómnibus funcionando localmente.

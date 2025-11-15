import { Controller } from "@hotwired/stimulus"
import L from "leaflet"

export default class extends Controller {
  static targets = ["container"]
  static values = { buses: Array }

  connect() {
    // Si el mapa ya está inicializado, no hacer nada
    if (this.map) {
      return
    }
    
    // Coordenadas de Montevideo (centro)
    const montevideoCenter = [-34.9011, -56.1645]
    
    // Inicializar mapa solo si el contenedor existe y no tiene un mapa
    if (this.containerTarget && !this.containerTarget._leaflet_id) {
      this.map = L.map(this.containerTarget).setView(montevideoCenter, 12)
      
      // Agregar capa de OpenStreetMap
      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: "© OpenStreetMap contributors",
        maxZoom: 19
      }).addTo(this.map)
      
      // Almacenar marcadores para poder eliminarlos
      this.markers = []
      
      // Mapa para almacenar colores por par origen-destino
      this.routeColors = new Map()
      
      // Colores disponibles para asignar a rutas
      this.colors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8",
        "#F7DC6F", "#BB8FCE", "#85C1E2", "#F8B739", "#52BE80",
        "#EC7063", "#5DADE2", "#58D68D", "#F4D03F", "#AF7AC5",
        "#85C1E9", "#F1948A", "#73C6B6", "#F7DC6F", "#A569BD",
        "#E74C3C", "#3498DB", "#2ECC71", "#F39C12", "#9B59B6",
        "#1ABC9C", "#E67E22", "#34495E", "#16A085", "#27AE60"
      ]
      
      this.colorIndex = 0
      
      // Observar cambios en el elemento map-data usando MutationObserver
      this.observeMapData()
      
      // Escuchar eventos personalizados para actualizar el mapa
      this.boundHandleMapUpdate = this.handleMapUpdate.bind(this)
      document.addEventListener('map:update', this.boundHandleMapUpdate)
      
      // Esperar un momento para asegurar que el DOM esté listo y que Leaflet haya inicializado
      setTimeout(() => {
        // Intentar leer del elemento map-data primero (más confiable)
        this.readFromMapData()
        // También intentar usar busesValue si está disponible
        if (this.busesValue && this.busesValue.length > 0) {
          this.updateMarkers(this.busesValue)
        }
      }, 300)
    }
  }
  
  observeMapData() {
    // Observar cambios en el elemento map-data
    const mapDataElement = document.getElementById('map-data')
    if (mapDataElement && window.MutationObserver) {
      this.mapDataObserver = new MutationObserver(() => {
        this.readFromMapData()
      })
      
      this.mapDataObserver.observe(mapDataElement, {
        attributes: true,
        attributeFilter: ['data-map-buses-value'],
        childList: true,
        subtree: true
      })
    }
  }
  
  readFromMapData() {
    // Primero intentar leer del script JSON (más confiable)
    const jsonScript = document.getElementById('map-data-json')
    if (jsonScript) {
      try {
        const buses = JSON.parse(jsonScript.textContent)
        if (buses && buses.length > 0) {
          this.updateMarkers(buses)
          return
        }
      } catch (e) {
        // Error al parsear buses del script
      }
    }
    
    // Fallback: leer del atributo data
    const mapDataElement = document.getElementById('map-data')
    if (mapDataElement) {
      const busesValue = mapDataElement.getAttribute('data-map-buses-value')
      
      if (busesValue && busesValue.trim() !== '' && busesValue !== '[]') {
        try {
          const buses = JSON.parse(busesValue)
          if (buses && buses.length > 0) {
            this.updateMarkers(buses)
          }
        } catch (e) {
          // Error al parsear buses del atributo
        }
      }
    }
  }
  
  handleMapUpdate(event) {
    if (event.detail && event.detail.buses) {
      // updateMarkers ya verifica si el mapa está inicializado
      this.updateMarkers(event.detail.buses)
    }
  }

  disconnect() {
    // Remover observer
    if (this.mapDataObserver) {
      this.mapDataObserver.disconnect()
      this.mapDataObserver = null
    }
    
    // Remover listener de eventos
    if (this.boundHandleMapUpdate) {
      document.removeEventListener('map:update', this.boundHandleMapUpdate)
    }
    
    if (this.map) {
      this.map.remove()
      this.map = null
    }
    this.markers = []
  }

  busesValueChanged() {
    // Si el mapa ya está inicializado, solo actualizar los marcadores
    if (this.map) {
      this.updateMarkers(this.busesValue)
    } else if (this.containerTarget) {
      // Si el mapa no está inicializado pero el contenedor existe, inicializar
      this.connect()
    }
  }

  updateMarkers(buses = null) {
    // Verificar que el mapa esté inicializado
    if (!this.map) {
      // Intentar inicializar si el contenedor existe
      if (this.containerTarget) {
        this.connect()
        // Esperar un momento y reintentar
        setTimeout(() => {
          if (this.map) {
            this.updateMarkers(buses)
          }
        }, 200)
      }
      return
    }
    
    // Si no se pasan buses, usar el valor del data attribute
    if (!buses) {
      buses = this.busesValue
    }
    
    // Limpiar marcadores anteriores
    this.markers.forEach(marker => {
      if (this.map) {
        this.map.removeLayer(marker)
      }
    })
    this.markers = []
    
    if (!buses || buses.length === 0) {
      return
    }
    
    let markersCreated = 0
    
    // Agregar marcadores para cada bus
    buses.forEach((bus, index) => {
      const location = bus.location
      if (location && location.coordinates && location.coordinates.length === 2) {
        const [lng, lat] = location.coordinates
        
        // Validar coordenadas
        if (isNaN(lat) || isNaN(lng)) {
          return
        }
        
        const origin = bus.origin || "N/A"
        const destination = bus.destination || "N/A"
        
        // Obtener color según el par origen-destino
        const color = this.getColorForRoute(origin, destination)
        
        // Crear marcador con etiqueta personalizada que muestra el número de línea
        const labelIcon = L.divIcon({
          className: "bus-label",
          html: `<div style="
            background-color: ${color};
            color: white;
            border: 3px solid white;
            border-radius: 50%;
            width: 35px;
            height: 35px;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 12px;
            box-shadow: 0 2px 6px rgba(0,0,0,0.4);
            cursor: pointer;
          ">${bus.line}</div>`,
          iconSize: [35, 35],
          iconAnchor: [22.5, 22.5]
        })
        
        try {
          const marker = L.marker([lat, lng], { icon: labelIcon, zIndexOffset: 1000 })
            .addTo(this.map)
          
          const fixedTimestamp = bus.timestamp.replace(/(\.\d{3})([-+]\d{2})$/, '$1$2:00');
          const actualizado = new Date(fixedTimestamp).toLocaleTimeString('en-GB', { 
            hour: '2-digit', 
            minute: '2-digit', 
            second: '2-digit',
            hour12: false 
          });

          // Crear popup con información del bus
          const popupContent = `
            <div class="p-2 min-w-[200px]">
              <strong>🚌 Línea ${bus.line}</strong><br/>
              <strong>Bus ID:</strong> ${bus.busId}<br/>
              <strong>Origen:</strong> ${bus.origin || "N/A"}<br/>
              <strong>Destino:</strong> ${bus.destination || "N/A"}<br/>
              ${bus.speed !== null && bus.speed !== undefined ? `<strong>Velocidad:</strong> ${bus.speed} km/h<br/>` : ""}
              ${bus.timestamp ? `<strong>Actualizado:</strong> ${actualizado}<br/>` : ""}
            </div>
          `

          
          marker.bindPopup(popupContent)
          
          this.markers.push(marker)
          markersCreated++
        } catch (e) {
          // Error al crear marcador
        }
      }
    })
    
    // Ajustar vista del mapa para mostrar todos los buses
    if (this.markers.length > 0 && this.map) {
      try {
        const group = new L.featureGroup(this.markers)
        this.map.fitBounds(group.getBounds().pad(0.1))
      } catch (e) {
        // Error al ajustar vista del mapa
      }
    }
  }

  getColorForRoute(origin, destination) {
    // Crear una clave única para el par origen-destino
    const routeKey = `${origin} → ${destination}`
    
    // Si ya tenemos un color para esta ruta, usarlo
    if (this.routeColors.has(routeKey)) {
      return this.routeColors.get(routeKey)
    }
    
    // Si no, asignar un nuevo color
    const color = this.colors[this.colorIndex % this.colors.length]
    this.routeColors.set(routeKey, color)
    this.colorIndex++
    
    return color
  }
}

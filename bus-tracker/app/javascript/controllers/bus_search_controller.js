import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "status"]
  static values = { debounce: Number }

  connect() {
    this.debounceValue = this.debounceValue || 3000 // 3 segundos por defecto
    this.timeout = null
    this.autoRefreshInterval = null
    this.currentLine = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    if (this.autoRefreshInterval) {
      clearInterval(this.autoRefreshInterval)
    }
  }

  search() {
    // Limpiar timeout anterior
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    const line = this.inputTarget.value.trim()

    if (line === "") {
      // Limpiar resultados y mostrar mensaje inicial
      this.resultsTarget.innerHTML = `
        <div class="mt-6">
          <div class="p-6 bg-gray-50 border border-gray-200 rounded-lg text-center">
            <p class="text-gray-600">Ingresa un número de línea para buscar buses</p>
          </div>
        </div>
      `
      this.statusTarget.innerHTML = ""
      return
    }

    // Mostrar estado de búsqueda
    this.statusTarget.innerHTML = '<p class="text-blue-600">🔍 Buscando...</p>'

    // Configurar nuevo timeout
    this.timeout = setTimeout(() => {
      this.performSearch(line)
    }, this.debounceValue)
  }

  performSearch(line) {
    // Guardar la línea actual para la actualización automática
    this.currentLine = line
    
    // Limpiar intervalo anterior
    if (this.autoRefreshInterval) {
      clearInterval(this.autoRefreshInterval)
    }
    
    // Realizar búsqueda inicial
    this.doSearch(line)
    
    // Configurar actualización automática cada 10 segundos
    this.autoRefreshInterval = setInterval(() => {
      if (this.currentLine) {
        this.doSearch(this.currentLine)
      }
    }, 10000) // 10 segundos
  }

  doSearch(line) {
    const url = `/buses?line=${encodeURIComponent(line)}`
    
    // Obtener HTML con Turbo Streams (incluye actualización del mapa)
    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => {
      if (response.ok) {
        return response.text()
      }
      throw new Error("Error en la búsqueda")
    })
    .then(html => {
      // Usar Turbo Streams para actualizar todo (resultados, mapa, status)
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      this.statusTarget.innerHTML = '<p class="text-red-600">❌ Error al buscar buses</p>'
    })
  }
}


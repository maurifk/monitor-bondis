require "httparty"

class OsrmService
  include HTTParty

  # URL base del servidor OSRM
  # Usa variable de entorno o por defecto el servidor local en puerto 5555
  BASE_URL = ENV.fetch("OSRM_URL", "http://localhost:5555")
  TIEMPO_ESPERA_POR_PARADA = 9
  TIEMPO_EXTRA_FACTOR = 1.4

  class << self
    # Calcula la ruta y duración entre múltiples puntos
    # coordinates: Array de [longitude, latitude]
    # Retorna: { duration: segundos, distance: metros } o nil si hay error
    def get_route(coordinates)
      return nil if coordinates.nil? || coordinates.length < 2

      # OSRM espera las coordenadas en formato: lon,lat;lon,lat;...
      coords_string = coordinates.map { |coord| "#{coord[0]},#{coord[1]}" }.join(";")

      url = "#{BASE_URL}/route/v1/driving/#{coords_string}"

      params = {
        overview: "false",  # No necesitamos la geometría completa
        steps: "false"      # No necesitamos instrucciones paso a paso
      }

      begin
        response = HTTParty.get(url, query: params, timeout: 10)

        if response.success? && response["code"] == "Ok"
          route = response["routes"]&.first

          if route
            {
              duration: route["duration"],      # En segundos
              distance: route["distance"]       # En metros
            }
          else
            Rails.logger.error "OSRM: No se encontró ruta"
            nil
          end
        else
          Rails.logger.error "OSRM Error: #{response['code']} - #{response['message']}"
          nil
        end
      rescue => e
        Rails.logger.error "Error al consultar OSRM: #{e.message}"
        nil
      end
    end

    # Calcula tiempo de llegada desde una posición de bus a una parada objetivo
    # bus_location: [longitude, latitude]
    # intermediate_stops: Array de BusStop entre la siguiente parada y la objetivo
    # target_stop: BusStop de destino
    def estimate_arrival_time(bus_location, intermediate_stops, target_stop)
      return nil if bus_location.nil? || target_stop.nil?

      # Construir array de coordenadas: posición del bus + paradas intermedias + parada objetivo
      coordinates = [ bus_location ]
      cantidad_intermedias = intermediate_stops.present? ? intermediate_stops.length : 0

      if intermediate_stops.present?
        coordinates += intermediate_stops.map { |stop| [ stop.longitude, stop.latitude ] }
      end

      coordinates << [ target_stop.longitude, target_stop.latitude ]

      route_info = get_route(coordinates)

      return nil unless route_info

      # Calcular tiempo estimado de llegada
      duration_seconds = (route_info[:duration] * TIEMPO_EXTRA_FACTOR + TIEMPO_ESPERA_POR_PARADA * cantidad_intermedias)
      duration_minutes = (duration_seconds / 60.0).round
      arrival_time = Time.current + duration_seconds.seconds

      {
        duration_seconds: duration_seconds,
        duration_minutes: duration_minutes,
        distance_meters: route_info[:distance],
        distance_km: (route_info[:distance] / 1000.0).round(2),
        estimated_arrival: arrival_time
      }
    end
  end
end

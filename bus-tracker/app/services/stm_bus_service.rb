require "httparty"

class StmBusService
  include HTTParty

  API_BASE_URL = "https://api.montevideo.gub.uy/api/transportepublico"

  # Configurar para mantener cookies (similar a requests.Session en Python)
  cookies({})

  class << self
    def get_buses_by_line(line)
      return nil unless StmAuthService.verify_token

      url = "#{API_BASE_URL}/buses"
      headers = {
        "Accept" => "application/json",
        "Authorization" => "Bearer #{StmAuthService.get_access_token}",
        "User-Agent" => "PostmanRuntime/7.50.0"
      }

      params = { lines: line }

      begin
        response = HTTParty.get(
          url,
          query: params,
          headers: headers,
          timeout: 10
        )

        if response.success?
          response.parsed_response
        else
          Rails.logger.error "Error al consultar la API: Status #{response.code}, Response: #{response.body[0..300]}"
          nil
        end
      rescue => e
        Rails.logger.error "Error al consultar la API: #{e.message}"
        nil
      end
    end
  end
end

require "httparty"

class StmAuthService
  include HTTParty

  AUTH_URL = "https://mvdapi-auth.montevideo.gub.uy/token"
  TOKEN_RENEWAL_BUFFER = 30 # Renovar 30 segundos antes de expirar

  # Configurar para mantener cookies (similar a requests.Session en Python)
  cookies({})

  class << self
    attr_accessor :access_token, :token_expiry

    def obtain_token
      headers = {
        "Content-Type" => "application/x-www-form-urlencoded",
        "User-Agent" => "PostmanRuntime/7.50.0",
        "Accept" => "*/*",
        "Cache-Control" => "no-cache",
        "Accept-Encoding" => "gzip, deflate, br",
        "Connection" => "keep-alive"
      }

      payload = { grant_type: "client_credentials" }
      client_id = ENV["CLIENT_ID"]&.strip
      client_secret = ENV["CLIENT_SECRET"]&.strip

      unless client_id && client_secret
        Rails.logger.error "CLIENT_ID o CLIENT_SECRET no están configurados"
        return false
      end

      begin
        Rails.logger.info "🔍 Obteniendo token de acceso..."

        response = HTTParty.post(
          AUTH_URL,
          body: payload,
          basic_auth: { username: client_id, password: client_secret },
          headers: headers,
          timeout: 10
        )

        Rails.logger.info "Status: #{response.code}"

        if response.success?
          token_data = response.parsed_response
          @access_token = token_data["access_token"]
          expires_in = token_data["expires_in"] || 300 # 300s por defecto
          @token_expiry = Time.now.to_i + expires_in - TOKEN_RENEWAL_BUFFER

          Rails.logger.info "✓ Token obtenido (válido por #{expires_in}s)"
          true
        else
          Rails.logger.error "Error al obtener token: Status #{response.code}, Response: #{response.body[0..500]}"
          false
        end
      rescue => e
        Rails.logger.error "❌ Error al obtener token: #{e.message}"
        false
      end
    end

    def verify_token
      if @access_token.nil? || Time.now.to_i >= @token_expiry
        obtain_token
      else
        true
      end
    end

    def get_access_token
      verify_token
      @access_token
    end
  end
end

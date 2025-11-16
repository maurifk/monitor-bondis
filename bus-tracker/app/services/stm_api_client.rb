require "httparty"

class StmApiClient
  include HTTParty

  BASE_URL = "https://api.montevideo.gub.uy/api/transportepublico/buses"

  def fetch_line_variants
    token = StmAuthService.get_access_token

    unless token
      raise "Failed to obtain access token"
    end

    headers = {
      "Accept" => "application/json",
      "Authorization" => "Bearer #{token}",
      "User-Agent" => "PostmanRuntime/7.50.0",
      "Cache-Control" => "no-cache"
    }

    response = self.class.get(
      "#{BASE_URL}/linevariants",
      headers: headers,
      timeout: 30
    )

    if response.success?
      response.parsed_response
    else
      raise "Error fetching line variants: #{response.code} - #{response.message}"
    end
  end
end

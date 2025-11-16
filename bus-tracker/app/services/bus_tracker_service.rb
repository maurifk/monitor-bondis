require "httparty"

class BusTrackerService
  include HTTParty

  BASE_URL = "https://api.montevideo.gub.uy/api/transportepublico/buses"
  EARTH_RADIUS_METERS = 6371000

  def initialize(bus_stop)
    @bus_stop = bus_stop
  end

  def fetch_buses_for_lines(lines, line_variant_ids = nil)
    token = StmAuthService.get_access_token
    return [] unless token

    params = { lines: Array(lines).join(",") }
    params[:lineVariantIds] = Array(line_variant_ids).join(",") if line_variant_ids.present?

    response = self.class.get(
      BASE_URL,
      query: params,
      headers: {
        "Authorization" => "Bearer #{token}",
        "Accept" => "application/json",
        "User-Agent" => "PostmanRuntime/7.50.0"
      },
      timeout: 10
    )

    return [] unless response.success?
    response.parsed_response || []
  end

  def process_bus_data(bus_data)
    return unless valid_bus_data?(bus_data)

    bus_id = bus_data["busId"]
    coordinates = bus_data.dig("location", "coordinates")
    api_timestamp = parse_timestamp(bus_data["timestamp"])

    return unless coordinates && api_timestamp

    longitude, latitude = coordinates
    distance = calculate_distance(latitude, longitude)

    tracking = find_or_create_tracking(bus_id, bus_data)
    tracking.add_position(
      latitude,
      longitude,
      distance,
      bus_data["speed"],
      api_timestamp
    )

    tracking
  end

  def mark_missing_buses(seen_bus_ids)
    active_trackings = BusTracking.active.for_stop(@bus_stop.id)
    active_trackings.each do |tracking|
      tracking.mark_missing unless seen_bus_ids.include?(tracking.bus_id)
    end
  end

  private

  def valid_bus_data?(data)
    data["busId"].present? &&
    data.dig("location", "coordinates").present? &&
    data["timestamp"].present?
  end

  def parse_timestamp(timestamp_str)
    Time.zone.parse(timestamp_str)
  rescue
    nil
  end

  def calculate_distance(lat, lon)
    lat1, lon1 = @bus_stop.latitude.to_f, @bus_stop.longitude.to_f
    lat2, lon2 = lat.to_f, lon.to_f

    dlat = deg_to_rad(lat2 - lat1)
    dlon = deg_to_rad(lon2 - lon1)

    a = Math.sin(dlat / 2)**2 +
        Math.cos(deg_to_rad(lat1)) * Math.cos(deg_to_rad(lat2)) *
        Math.sin(dlon / 2)**2

    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    EARTH_RADIUS_METERS * c
  end

  def deg_to_rad(degrees)
    degrees * Math::PI / 180
  end

  def find_or_create_tracking(bus_id, bus_data)
    BusTracking.find_or_create_by!(
      bus_stop: @bus_stop,
      bus_id: bus_id
    ) do |tracking|
      tracking.line = bus_data["line"]
      tracking.line_variant_id = bus_data["lineVariantId"]
      tracking.tracking_active = true
      tracking.last_seen_at = Time.current
    end
  end
end

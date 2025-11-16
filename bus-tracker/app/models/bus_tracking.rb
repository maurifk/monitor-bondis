class BusTracking < ApplicationRecord
  belongs_to :bus_stop
  has_many :bus_positions, dependent: :destroy

  MAX_POSITIONS = 30
  MAX_MISSING_COUNT = 3
  MAX_MINUTES = 10

  validates :bus_id, presence: true
  validates :line, presence: true

  scope :active, -> { where(tracking_active: true) }
  scope :for_stop, ->(stop_id) { where(bus_stop_id: stop_id) }
  scope :recent, -> { where("last_seen_at > ?", 5.minutes.ago) }

  def add_position(latitude, longitude, distance, speed, api_timestamp)
    return if bus_positions.exists?(api_timestamp: api_timestamp)

    bus_positions.create!(
      latitude: latitude,
      longitude: longitude,
      distance_to_stop: distance,
      speed: speed,
      api_timestamp: api_timestamp
    )

    calculated_speed = calculate_average_speed
    has_passed = check_if_passed_stop

    update(
      latitude: latitude,
      longitude: longitude,
      distance_to_stop: distance,
      speed: calculated_speed,
      api_timestamp: api_timestamp,
      last_seen_at: Time.current,
      missing_count: 0
    )

    cleanup_old_positions
  end

  def mark_missing
    increment!(:missing_count)
    # Don't deactivate automatically - let users stop tracking manually
    # update(tracking_active: false) if missing_count >= MAX_MISSING_COUNT
  end

  def calculate_average_speed
    recent_positions = bus_positions.order(api_timestamp: :desc).limit(20)
    return nil if recent_positions.count < 2

    total_distance_change = 0
    total_time_seconds = 0
    valid_measurements = 0

    recent_positions.each_cons(2) do |newer, older|
      distance_change = (older.distance_to_stop - newer.distance_to_stop)
      time_diff = (newer.api_timestamp - older.api_timestamp).to_f

      total_distance_change += distance_change
      total_time_seconds += time_diff
      valid_measurements += 1
    end

    return nil if total_time_seconds.zero? || valid_measurements.zero?

    # Speed in meters per second
    avg_speed_mps = total_distance_change / total_time_seconds
    # Convert to km/h
    (avg_speed_mps * 3.6).round(2)
  end

  def check_if_passed_stop
    recent_positions = bus_positions.order(api_timestamp: :desc).limit(5)
    return false if recent_positions.count < 5

    # Check if distance is increasing in last 5 measurements
    distances = recent_positions.map(&:distance_to_stop).reverse

    # Count how many times distance increased
    increases = 0
    distances.each_cons(2) do |older, newer|
      increases += 1 if newer > older
    end

    # If 4 or more increases out of 4 comparisons, bus has passed
    increases >= 4
  end

  def has_passed_stop?
    check_if_passed_stop
  end

  def estimated_arrival_time
    return nil unless tracking_active && bus_positions.count >= 3
    return nil if has_passed_stop?
    return nil if distance_to_stop.nil? || distance_to_stop <= 0

    avg_speed_kmh = speed || calculate_average_speed
    return nil unless avg_speed_kmh && avg_speed_kmh > 0

    # Convert speed from km/h to m/s
    avg_speed_mps = avg_speed_kmh / 3.6

    seconds_to_arrival = distance_to_stop / avg_speed_mps
    Time.current + seconds_to_arrival.seconds
  end

  def estimated_minutes_to_arrival
    eta = estimated_arrival_time
    return nil unless eta

    minutes = ((eta - Time.current) / 60.0).round
    [ minutes, 0 ].max
  end

  scope :approaching, -> {
    active.select { |t| !t.has_passed_stop? }
  }

  private

  def cleanup_old_positions
    # delete positions older than MAX_MINUTES
    bus_positions.where("api_timestamp < ?", Time.current - MAX_MINUTES.minutes).destroy_all

    if bus_positions.count > MAX_POSITIONS
      excess_count = bus_positions.count - MAX_POSITIONS
      bus_positions.order(api_timestamp: :asc).limit(excess_count).destroy_all
    end
  end
end

class BusStop < ApplicationRecord
  has_many :bus_passages, dependent: :destroy
  has_many :bus_schedules, dependent: :destroy
  has_many :line_variants, through: :bus_schedules
  has_many :bus_trackings, dependent: :destroy

  validates :busstop_id, presence: true, uniqueness: true
  validates :latitude, :longitude, presence: true
  # street1 and street2 can be null from API

  def self.find_or_create_from_api(data)
    find_or_create_by(busstop_id: data["busstopId"]) do |stop|
      stop.street1 = data["street1"] || "SIN NOMBRE"
      stop.street2 = data["street2"] || "SIN DENOMINACIÓN"
      stop.street1_id = data["street1Id"]
      stop.street2_id = data["street2Id"]
      stop.latitude = data.dig("location", "coordinates", 1)
      stop.longitude = data.dig("location", "coordinates", 0)
    end
  end

  def coordinates
    [latitude, longitude]
  end

  def full_name
    parts = [street1 || "Sin nombre", street2 || "Sin denominación"]
    parts.join(" y ")
  end
end

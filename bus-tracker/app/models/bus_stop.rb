class BusStop < ApplicationRecord
  has_many :bus_passages, dependent: :destroy
  has_many :bus_schedules, dependent: :destroy
  has_many :line_variants, through: :bus_schedules
  has_many :bus_trackings, dependent: :destroy

  validates :busstop_id, presence: true, uniqueness: true
  validates :street1, :street2, :latitude, :longitude, presence: true

  def self.find_or_create_from_api(data)
    find_or_create_by(busstop_id: data["busstopId"]) do |stop|
      stop.street1 = data["street1"]
      stop.street2 = data["street2"]
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
    "#{street1} y #{street2}"
  end
end

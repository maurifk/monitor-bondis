class BusPassage < ApplicationRecord
  belongs_to :bus_stop

  validates :line, :detected_at, presence: true

  scope :recent, -> { order(detected_at: :desc) }
  scope :by_line, ->(line) { where(line: line) }
  scope :for_stop, ->(stop_id) { where(bus_stop_id: stop_id) }
  scope :today, -> { where("detected_at >= ?", Time.current.beginning_of_day) }

  def self.create_from_bus_data(bus_stop, bus_data, detected_at = Time.current)
    create(
      bus_stop: bus_stop,
      line: bus_data["line"],
      destination: bus_data["destination"],
      bus_code: bus_data["busCode"],
      bus_latitude: bus_data.dig("location", "coordinates", 1),
      bus_longitude: bus_data.dig("location", "coordinates", 0),
      detected_at: detected_at,
      eta_minutes: bus_data.dig("eta", "minutes")
    )
  end
end

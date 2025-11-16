class BusPosition < ApplicationRecord
  belongs_to :bus_tracking

  validates :latitude, :longitude, :distance_to_stop, :api_timestamp, presence: true

  scope :ordered, -> { order(api_timestamp: :desc) }
  scope :recent, ->(count = 30) { ordered.limit(count) }
end

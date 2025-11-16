class LineVariant < ApplicationRecord
  belongs_to :line
  has_many :bus_schedules, dependent: :destroy
  has_many :bus_stops, through: :bus_schedules

  validates :line_number, presence: true
  validates :origin, presence: true
  validates :destination, presence: true
  validates :api_line_variant_id, presence: true, uniqueness: true
  validates :special, inclusion: { in: [true, false] }
end

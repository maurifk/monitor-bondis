class Line < ApplicationRecord
  has_many :line_variants, dependent: :destroy
  has_many :bus_schedules, through: :line_variants

  validates :line_number, presence: true, uniqueness: true
  validates :api_line_id, uniqueness: true, allow_nil: true
end

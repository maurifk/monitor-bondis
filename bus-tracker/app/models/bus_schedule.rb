class BusSchedule < ApplicationRecord
  belongs_to :line_variant
  belongs_to :bus_stop

  enum :day_type, { weekday: 1, saturday: 2, sunday: 3 }, prefix: true

  validates :day_type, presence: true
  validates :frequency, presence: true
  validates :ordinal, presence: true, numericality: { greater_than: 0 }
  validates :scheduled_time, presence: true
  validates :previous_day, presence: true, inclusion: { in: %w[N S *] }

  scope :for_day_type, ->(day_type) { where(day_type: day_type) }
  scope :at_stop, ->(bus_stop_id) { where(bus_stop_id: bus_stop_id) }
  scope :for_variant, ->(variant_id) { where(line_variant_id: variant_id) }
  scope :for_frequency, ->(freq_int) { where(frequency: freq_int) }
  scope :after_time, ->(time_int) { where("scheduled_time >= ?", time_int) }
  scope :ordered_by_time, -> { order(:scheduled_time) }
  scope :ordered_by_ordinal, -> { order(:ordinal) }

  def scheduled_time_formatted
    time_str = scheduled_time.to_s.rjust(3, "0")
    hours = time_str[0...-2].to_i
    minutes = time_str[-2..-1]
    "#{hours.to_s.rjust(2, '0')}:#{minutes}"
  end

  def scheduled_time_in_minutes
    time_str = scheduled_time.to_s.rjust(3, "0")
    hours = time_str[0...-2].to_i
    minutes = time_str[-2..-1].to_i
    total_minutes = hours * 60 + minutes

    total_minutes += 24 * 60 if previous_day == "S"
    total_minutes
  end

  def self.next_buses_at_stop(bus_stop_id, current_time_minutes, day_type, limit: 10)
    at_stop(bus_stop_id)
      .for_day_type(day_type)
      .select("bus_schedules.*,
               CASE
                 WHEN previous_day = 'S' THEN (scheduled_time + 1440) - #{current_time_minutes}
                 WHEN scheduled_time >= #{current_time_minutes} THEN scheduled_time - #{current_time_minutes}
                 ELSE scheduled_time + 1440 - #{current_time_minutes}
               END as wait_minutes")
      .where("CASE
                WHEN previous_day = 'S' THEN (scheduled_time + 1440) >= #{current_time_minutes}
                ELSE scheduled_time >= #{current_time_minutes}
              END")
      .order("wait_minutes ASC")
      .limit(limit)
  end
end

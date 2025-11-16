class StopTracking < ApplicationRecord
  belongs_to :bus_stop

  serialize :lines, coder: JSON
  serialize :line_variant_ids, coder: JSON

  validates :bus_stop, presence: true
  validates :lines, presence: true

  scope :active, -> { where(active: true) }

  before_create :set_started_at

  def lines_display
    Array(lines).join(', ')
  end

  def variants_display
    return 'todas' if line_variant_ids.blank?
    Array(line_variant_ids).join(', ')
  end

  def mark_job_run
    update(last_job_run_at: Time.current)
  end

  private

  def set_started_at
    self.started_at ||= Time.current
  end
end

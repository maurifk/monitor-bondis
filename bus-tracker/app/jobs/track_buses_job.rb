class TrackBusesJob < ApplicationJob
  queue_as :default

  # This job runs once, then re-enqueues itself to run again in 15 seconds
  # This allows Solid Queue to process other jobs and prevents blocking
  def perform(stop_tracking_id)
    stop_tracking = StopTracking.find_by(id: stop_tracking_id)
    
    # Check if tracking is still active
    unless stop_tracking&.active?
      Rails.logger.info "Stop tracking #{stop_tracking_id} is not active, stopping job"
      return
    end
    
    # Update last job run time
    stop_tracking.mark_job_run
    
    bus_stop = stop_tracking.bus_stop
    lines = stop_tracking.lines
    line_variant_ids = stop_tracking.line_variant_ids
    
    tracker = BusTrackerService.new(bus_stop)
    
    begin
      buses_data = tracker.fetch_buses_for_lines(lines, line_variant_ids)
      seen_bus_ids = []
      
      if buses_data.any?
        buses_data.each do |bus_data|
          tracking = tracker.process_bus_data(bus_data)
          seen_bus_ids << bus_data['busId'] if tracking
        end
        
        tracker.mark_missing_buses(seen_bus_ids)
        
        Rails.logger.info "✓ Tracked #{seen_bus_ids.count} buses for stop #{bus_stop.id} (#{bus_stop.full_name})"
      else
        Rails.logger.info "No buses found for stop #{bus_stop.id}, lines: #{lines.join(', ')}"
      end
      
    rescue => e
      Rails.logger.error "Error tracking buses for stop #{bus_stop.id}: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
    end
    
    # Re-enqueue this job to run again in 15 seconds
    TrackBusesJob.set(wait: 15.seconds).perform_later(stop_tracking_id)
  end
end

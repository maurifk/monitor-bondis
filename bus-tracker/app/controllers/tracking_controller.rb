class TrackingController < ApplicationController
  def index
    @bus_stops = BusStop.order(:street1, :street2)
  end

  def dashboard
    @bus_stop = BusStop.find(params[:bus_stop_id])
    @stop_tracking = StopTracking.active.find_by(bus_stop: @bus_stop)
    
    all_trackings = BusTracking.for_stop(@bus_stop.id)
                               .where('last_seen_at > ?', 5.minutes.ago)
                               .includes(:bus_positions)

    # Filter out buses that have passed the stop
    @active_trackings = all_trackings.select { |t| !t.has_passed_stop? }
                                     .sort_by { |t| t.distance_to_stop || Float::INFINITY }

    respond_to do |format|
      format.html
      format.json do
        render json: @active_trackings.map { |tracking|
          {
            bus_id: tracking.bus_id,
            line: tracking.line,
            line_variant_id: tracking.line_variant_id,
            distance_to_stop: tracking.distance_to_stop&.round(2),
            speed: tracking.speed&.round(1),
            estimated_minutes: tracking.estimated_minutes_to_arrival,
            last_seen: tracking.last_seen_at,
            positions_count: tracking.bus_positions.count,
            has_passed: tracking.has_passed_stop?
          }
        }
      end
    end
  end

  def start_tracking
    bus_stop = BusStop.find(params[:bus_stop_id])
    lines = params[:lines]&.split(",")&.map(&:strip) || []
    line_variant_ids = params[:line_variant_ids]&.split(",")&.map(&:strip)
    line_variant_ids = nil if line_variant_ids&.empty?

    if lines.empty?
      flash[:alert] = "Debes especificar al menos una línea"
      redirect_to tracking_index_path and return
    end

    # Check if already tracking this stop
    if StopTracking.active.exists?(bus_stop: bus_stop)
      flash[:alert] = "Ya hay tracking activo para esta parada. Detén el tracking anterior primero."
      redirect_to tracking_dashboard_path(bus_stop_id: bus_stop.id) and return
    end

    # Create stop tracking record
    stop_tracking = StopTracking.create!(
      bus_stop: bus_stop,
      lines: lines,
      line_variant_ids: line_variant_ids,
      active: true,
      started_at: Time.current
    )

    # Start the job in background (returns immediately)
    TrackBusesJob.perform_later(stop_tracking.id)

    flash[:notice] = "Tracking iniciado en background para parada #{bus_stop.full_name}. Los datos comenzarán a aparecer en unos segundos."
    redirect_to tracking_dashboard_path(bus_stop_id: bus_stop.id)
  end

  def stop_tracking
    bus_stop = BusStop.find(params[:bus_stop_id])

    # Mark stop tracking as inactive (this will stop the job)
    StopTracking.active.where(bus_stop: bus_stop).update_all(active: false)

    # Also mark bus trackings as inactive
    BusTracking.active.for_stop(bus_stop.id).update_all(tracking_active: false)

    flash[:notice] = "Tracking detenido para parada #{bus_stop.full_name}"
    redirect_to tracking_index_path
  end
end

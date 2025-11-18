class StopsController < ApplicationController
  def index
    @query = params[:query]&.strip || ""
    @stops = if @query.present?
      BusStop.where("street1 ILIKE ? OR street2 ILIKE ? OR busstop_id::text LIKE ?", 
                    "%#{@query}%", "%#{@query}%", "%#{@query}%")
              .order(:street1, :street2)
              .limit(50)
    else
      []
    end
  end

  def show
    @stop = BusStop.find_by(busstop_id: params[:id])
    
    unless @stop
      redirect_to stops_path, alert: "Parada no encontrada"
      return
    end

    # Obtener todas las variantes que pasan por esta parada
    @variants = @stop.line_variants.includes(:line)
    
    # Obtener todas las líneas únicas de las variantes
    lines = @variants.map(&:line_number).uniq
    
    # Obtener buses de todas esas líneas
    @approaching_buses = []
    
    lines.each do |line_number|
      buses = StmBusService.get_buses_by_line(line_number) || []
      
      buses.each do |bus|
        variant = LineVariant.find_by(api_line_variant_id: bus["lineVariantId"])
        next unless variant
        
        # Verificar que esta variante pasa por la parada seleccionada
        next unless variant.bus_stops.exists?(busstop_id: @stop.busstop_id)
        
        # Calcular la siguiente parada del bus
        if bus["location"] && bus["location"]["coordinates"]
          longitude = bus["location"]["coordinates"][0]
          latitude = bus["location"]["coordinates"][1]
          
          next_stop = variant.estimate_next_stop(latitude, longitude)
          
          # Verificar si el bus aún no pasó por nuestra parada
          # (la siguiente parada debe ser nuestra parada o una anterior en el recorrido)
          if next_stop && variant.stop_comes_before_or_at?(next_stop.busstop_id, @stop.busstop_id)
            # Calcular tiempo de llegada estimado usando OSRM
            bus_location = [longitude, latitude]
            intermediate_stops = variant.stops_between(next_stop.busstop_id, @stop.busstop_id)
            
            arrival_estimate = OsrmService.estimate_arrival_time(
              bus_location,
              intermediate_stops,
              @stop
            )
            
            @approaching_buses << {
              bus: bus,
              variant: variant,
              next_stop: next_stop,
              arrival_estimate: arrival_estimate
            }
          end
        end
      end
    end
    
    # Ordenar por tiempo de llegada estimado (los que tienen estimación primero)
    @approaching_buses.sort_by! do |ab|
      if ab[:arrival_estimate]
        ab[:arrival_estimate][:duration_seconds]
      else
        Float::INFINITY  # Los que no tienen estimación van al final
      end
    end
  end
end

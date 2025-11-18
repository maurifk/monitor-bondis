class BusesController < ApplicationController
  def index
    @line = params[:line]&.strip || ""
    @buses = @line.present? ? (StmBusService.get_buses_by_line(@line) || []) : []
    @error = nil

    # Verificar credenciales
    unless ENV["CLIENT_ID"].present? && ENV["CLIENT_SECRET"].present?
      @error = "CLIENT_ID o CLIENT_SECRET no están configurados. Por favor, configura el archivo .env"
    end

    # Enriquecer datos de buses con información de siguiente parada
    if @buses.any?
      @buses = enrich_buses_with_next_stop(@buses)
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  private

  def enrich_buses_with_next_stop(buses)
    buses.map do |bus|
      # Buscar la variante correspondiente
      variant = find_variant_for_bus(bus)
      
      if variant && bus["location"] && bus["location"]["coordinates"]
        longitude = bus["location"]["coordinates"][0]
        latitude = bus["location"]["coordinates"][1]
        
        next_stop = variant.estimate_next_stop(latitude, longitude)
        bus["next_stop"] = next_stop ? {
          "name" => next_stop.full_name,
          "id" => next_stop.busstop_id
        } : nil
      end
      
      bus
    end
  end

  def find_variant_for_bus(bus)
    return nil unless bus["lineVariantId"]
    
    LineVariant.find_by(api_line_variant_id: bus["lineVariantId"])
  end

  def show
    @line = params[:id]&.strip
    @buses = StmBusService.get_buses_by_line(@line) || []

    respond_to do |format|
      format.json { render json: @buses }
      format.html { redirect_to buses_path(line: @line) }
    end
  end
end

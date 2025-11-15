class BusesController < ApplicationController
  def index
    @line = params[:line]&.strip || ""
    @buses = @line.present? ? (StmBusService.get_buses_by_line(@line) || []) : []
    @error = nil

    # Verificar credenciales
    unless ENV["CLIENT_ID"].present? && ENV["CLIENT_SECRET"].present?
      @error = "CLIENT_ID o CLIENT_SECRET no están configurados. Por favor, configura el archivo .env"
    end

    respond_to do |format|
      format.html
      format.turbo_stream
    end
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

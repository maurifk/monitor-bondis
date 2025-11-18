class LineVariant < ApplicationRecord
  belongs_to :line
  has_many :bus_schedules, dependent: :destroy
  has_many :bus_stops, through: :bus_schedules

  validates :line_number, presence: true
  validates :origin, presence: true
  validates :destination, presence: true
  validates :api_line_variant_id, presence: true, uniqueness: true
  validates :special, inclusion: { in: [ true, false ] }

  def stops_in_order
    bus_stops
      .select("bus_stops.*, bus_schedules.ordinal AS schedule_ordinal")
      .joins(:bus_schedules)
      .where(bus_schedules: { line_variant_id: id })
      .group("bus_stops.id, bus_schedules.ordinal")
      .order("schedule_ordinal ASC")
  end

  def estimate_next_stop(latitude, longitude)
    return nil if latitude.nil? || longitude.nil?

    stops = stops_in_order.to_a
    return nil if stops.empty?
    return stops.first if stops.length == 1

    # Calcular la distancia del bus a cada segmento (par de paradas consecutivas)
    best_segment = nil
    min_distance_to_segment = Float::INFINITY

    (0...(stops.length - 1)).each do |i|
      stop_a = stops[i]
      stop_b = stops[i + 1]

      # Calcular distancia perpendicular del punto al segmento
      distance_to_segment = point_to_segment_distance(
        latitude, longitude,
        stop_a.latitude, stop_a.longitude,
        stop_b.latitude, stop_b.longitude
      )

      if distance_to_segment < min_distance_to_segment
        min_distance_to_segment = distance_to_segment
        best_segment = { from: stop_a, to: stop_b, index: i }
      end
    end

    # Devolver la parada destino del segmento más cercano
    best_segment ? best_segment[:to] : stops.first
  end

  def stop_comes_before_or_at?(stop_a_id, stop_b_id)
    stops = stops_in_order.to_a

    ordinal_a = stops.find { |s| s.busstop_id == stop_a_id }&.schedule_ordinal
    ordinal_b = stops.find { |s| s.busstop_id == stop_b_id }&.schedule_ordinal

    return false if ordinal_a.nil? || ordinal_b.nil?

    ordinal_a <= ordinal_b
  end

  def stops_between(from_stop_id, to_stop_id)
    stops = stops_in_order.to_a

    from_stop = stops.find { |s| s.busstop_id == from_stop_id }
    to_stop = stops.find { |s| s.busstop_id == to_stop_id }

    return [] if from_stop.nil? || to_stop.nil?

    from_ordinal = from_stop.schedule_ordinal
    to_ordinal = to_stop.schedule_ordinal

    return [] if from_ordinal >= to_ordinal

    # Retornar paradas entre from y to (excluyendo ambas)
    stops.select do |stop|
      stop.schedule_ordinal > from_ordinal && stop.schedule_ordinal < to_ordinal
    end
  end

  private

  def calculate_distance(lat1, lon1, lat2, lon2)
    # Fórmula de Haversine para calcular distancia entre dos puntos en la Tierra
    rad_per_deg = Math::PI / 180
    earth_radius_km = 6371

    dlat = (lat2 - lat1) * rad_per_deg
    dlon = (lon2 - lon1) * rad_per_deg

    lat1_rad = lat1 * rad_per_deg
    lat2_rad = lat2 * rad_per_deg

    a = Math.sin(dlat / 2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon / 2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

    earth_radius_km * c
  end

  def point_to_segment_distance(px, py, ax, ay, bx, by)
    # Calcular la distancia perpendicular de un punto P a un segmento AB

    # Distancia de A a B
    ab_distance = calculate_distance(ax, ay, bx, by)
    return calculate_distance(px, py, ax, ay) if ab_distance == 0

    # Proyección del punto sobre la línea que contiene el segmento
    # Usando producto punto para encontrar el parámetro t
    # Convertir a coordenadas cartesianas aproximadas para el cálculo
    dx = (bx - ax) * 111.32 # km por grado de longitud (aproximado)
    dy = (by - ay) * 110.57 # km por grado de latitud

    px_rel = (px - ax) * 111.32
    py_rel = (py - ay) * 110.57

    # Producto punto y normalización
    dot_product = px_rel * dx + py_rel * dy
    len_sq = dx * dx + dy * dy

    t = dot_product / len_sq

    # Limitar t entre 0 y 1 para que esté dentro del segmento
    t = [ [ t, 0 ].max, 1 ].min

    # Punto más cercano en el segmento
    closest_x = ax + t * (bx - ax)
    closest_y = ay + t * (by - ay)

    # Distancia del punto al punto más cercano en el segmento
    calculate_distance(px, py, closest_x, closest_y)
  end
end

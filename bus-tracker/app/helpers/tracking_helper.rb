module TrackingHelper
  def eta_display(tracking)
    return content_tag(:span, "Ya pasó", class: "text-orange-600") if tracking.has_passed_stop?
    
    eta = tracking.estimated_minutes_to_arrival
    return content_tag(:span, "Calculando...", class: "text-gray-400") unless eta
    
    if eta == 0
      content_tag(:span, "¡Llegando!", class: "text-red-600 font-bold animate-pulse")
    elsif eta <= 2
      content_tag(:span, "#{eta} min", class: "text-red-600 font-bold")
    elsif eta <= 5
      content_tag(:span, "#{eta} min", class: "text-orange-600 font-semibold")
    else
      content_tag(:span, "#{eta} min", class: "text-green-600")
    end
  end
  
  def distance_display(distance)
    return "N/A" unless distance
    
    if distance < 1000
      "#{distance.round(0)} m"
    else
      "#{(distance / 1000.0).round(1)} km"
    end
  end
  
  def speed_display(speed)
    return content_tag(:span, "Calculando...", class: "text-gray-400") unless speed
    
    "#{number_with_precision(speed, precision: 1)} km/h"
  end
  
  def tracking_status_badge(tracking)
    if tracking.has_passed_stop?
      content_tag(:span, "⚠️ Pasó", class: "bg-orange-100 text-orange-800 px-2 py-1 rounded text-xs")
    elsif tracking.distance_to_stop && tracking.distance_to_stop < 100
      content_tag(:span, "🎯 Llegando", class: "bg-red-100 text-red-800 px-2 py-1 rounded text-xs animate-pulse")
    elsif tracking.distance_to_stop && tracking.distance_to_stop < 300
      content_tag(:span, "🚍 Muy cerca", class: "bg-green-100 text-green-800 px-2 py-1 rounded text-xs")
    elsif tracking.distance_to_stop && tracking.distance_to_stop < 1000
      content_tag(:span, "🚌 Acercándose", class: "bg-blue-100 text-blue-800 px-2 py-1 rounded text-xs")
    end
  end
end

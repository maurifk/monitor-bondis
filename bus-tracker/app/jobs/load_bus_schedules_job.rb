require 'csv'

class LoadBusSchedulesJob < ApplicationJob
  queue_as :default

  def perform(csv_path = nil)
    csv_path ||= Rails.root.join('..', 'datos_stm.csv')
    
    unless File.exist?(csv_path)
      Rails.logger.error "CSV file not found: #{csv_path}"
      return { success: false, error: "CSV file not found" }
    end

    Rails.logger.info "Loading bus schedules from: #{csv_path}"
    
    processed = 0
    skipped = 0
    errors = 0
    batch_size = 1000
    batch = []
    
    # Cache for variants and stops to avoid repeated queries
    variant_cache = {}
    stop_cache = {}
    
    CSV.foreach(csv_path, headers: true, col_sep: ';') do |row|
      begin
        variant_code = row['cod_variante']
        stop_code = row['cod_ubic_parada']
        
        # Find or cache line variant
        unless variant_cache[variant_code]
          variant = LineVariant.find_by(api_line_variant_id: variant_code)
          unless variant
            skipped += 1
            next
          end
          variant_cache[variant_code] = variant.id
        end
        
        # Find or cache bus stop
        unless stop_cache[stop_code]
          stop = BusStop.find_by(busstop_id: stop_code)
          unless stop
            skipped += 1
            next
          end
          stop_cache[stop_code] = stop.id
        end
        
        batch << {
          line_variant_id: variant_cache[variant_code],
          bus_stop_id: stop_cache[stop_code],
          day_type: row['tipo_dia'].to_i,
          frequency: row['frecuencia'].to_i,
          ordinal: row['ordinal'].to_i,
          scheduled_time: row['hora'].to_i,
          previous_day: row['dia_anterior'] || 'N',
          created_at: Time.current,
          updated_at: Time.current
        }
        
        if batch.size >= batch_size
          BusSchedule.insert_all(batch)
          processed += batch.size
          batch = []
          Rails.logger.info "Processed #{processed} schedules..." if processed % 10000 == 0
        end
      rescue => e
        Rails.logger.error "Error processing row: #{e.message}"
        errors += 1
      end
    end
    
    # Insert remaining records
    if batch.any?
      BusSchedule.insert_all(batch)
      processed += batch.size
    end
    
    Rails.logger.info "✓ Schedule loading complete"
    Rails.logger.info "  Processed: #{processed}"
    Rails.logger.info "  Skipped: #{skipped} (missing variants or stops)"
    Rails.logger.info "  Errors: #{errors}"
    
    {
      success: true,
      processed: processed,
      skipped: skipped,
      errors: errors,
      total_schedules: BusSchedule.count
    }
  end
end

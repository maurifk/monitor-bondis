class LoadLineVariantsJob < ApplicationJob
  queue_as :default

  def perform
    client = StmApiClient.new
    variants_data = client.fetch_line_variants
    
    Rails.logger.info "Fetched #{variants_data.size} line variants from API"
    
    variants_data.each do |variant|
      line = Line.find_or_create_by!(
        line_number: variant["line"]
      ) do |l|
        l.api_line_id = variant["lineId"]
        l.name = variant["subline"]
      end
      
      # Update api_line_id if it was nil
      if line.api_line_id.nil? && variant["lineId"].present?
        line.update!(api_line_id: variant["lineId"])
      end
      
      LineVariant.find_or_create_by!(
        api_line_variant_id: variant["lineVariantId"]
      ) do |lv|
        lv.line = line
        lv.line_number = variant["line"]
        lv.origin = variant["origin"]
        lv.destination = variant["destination"]
        lv.subline = variant["subline"]
        lv.special = variant["special"] || false
      end
    end
    
    Rails.logger.info "Successfully loaded #{Line.count} lines and #{LineVariant.count} variants"
    
    {
      lines_count: Line.count,
      variants_count: LineVariant.count,
      message: "Data loaded successfully"
    }
  end
end

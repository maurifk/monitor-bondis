class CreateBusTrackings < ActiveRecord::Migration[8.0]
  def change
    create_table :bus_trackings do |t|
      t.references :bus_stop, null: false, foreign_key: true
      t.integer :bus_id, null: false
      t.string :line, null: false
      t.integer :line_variant_id
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.decimal :distance_to_stop, precision: 10, scale: 2
      t.integer :speed
      t.datetime :api_timestamp
      t.datetime :last_seen_at
      t.boolean :tracking_active, default: true, null: false
      t.integer :missing_count, default: 0, null: false

      t.timestamps
    end
    
    add_index :bus_trackings, [:bus_stop_id, :bus_id], name: 'idx_bus_trackings_stop_bus'
    add_index :bus_trackings, [:bus_stop_id, :tracking_active], name: 'idx_bus_trackings_stop_active'
    add_index :bus_trackings, :last_seen_at
  end
end

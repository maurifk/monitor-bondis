class CreateBusPositions < ActiveRecord::Migration[8.0]
  def change
    create_table :bus_positions do |t|
      t.references :bus_tracking, null: false, foreign_key: true
      t.decimal :latitude, precision: 10, scale: 7, null: false
      t.decimal :longitude, precision: 10, scale: 7, null: false
      t.decimal :distance_to_stop, precision: 10, scale: 2, null: false
      t.integer :speed
      t.datetime :api_timestamp, null: false

      t.timestamps
    end
    
    add_index :bus_positions, [:bus_tracking_id, :api_timestamp], name: 'idx_bus_positions_tracking_time'
    add_index :bus_positions, :api_timestamp
  end
end

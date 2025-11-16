class CreateBusStops < ActiveRecord::Migration[8.0]
  def change
    create_table :bus_stops do |t|
      t.integer :busstop_id, null: false
      t.string :street1, null: false
      t.string :street2, null: false
      t.integer :street1_id
      t.integer :street2_id
      t.decimal :latitude, precision: 10, scale: 8, null: false
      t.decimal :longitude, precision: 11, scale: 8, null: false

      t.timestamps
    end

    add_index :bus_stops, :busstop_id, unique: true
    add_index :bus_stops, [:latitude, :longitude]
  end
end

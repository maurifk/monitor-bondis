class CreateBusPassages < ActiveRecord::Migration[8.0]
  def change
    create_table :bus_passages do |t|
      t.references :bus_stop, null: false, foreign_key: true
      t.string :line, null: false
      t.string :destination
      t.string :bus_code
      t.decimal :bus_latitude, precision: 10, scale: 8
      t.decimal :bus_longitude, precision: 11, scale: 8
      t.datetime :detected_at, null: false
      t.integer :eta_minutes

      t.timestamps
    end

    add_index :bus_passages, [:bus_stop_id, :detected_at]
    add_index :bus_passages, :line
    add_index :bus_passages, :detected_at
  end
end

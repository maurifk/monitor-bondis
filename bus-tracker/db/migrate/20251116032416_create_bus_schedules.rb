class CreateBusSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :bus_schedules do |t|
      t.references :line_variant, null: false, foreign_key: true
      t.references :bus_stop, null: false, foreign_key: true
      t.integer :day_type, null: false, comment: "1=Hábil, 2=Sábado, 3=Domingo"
      t.integer :frequency, null: false, comment: "Hora de salida en formato hmm0"
      t.integer :ordinal, null: false, comment: "Número ordinal de parada en recorrido"
      t.integer :scheduled_time, null: false, comment: "Hora de pasada en formato hmm"
      t.string :previous_day, limit: 1, null: false, default: "N", comment: "N=mismo día, S=día anterior, *=especial"

      t.timestamps
    end
    
    add_index :bus_schedules, [:line_variant_id, :bus_stop_id, :day_type, :frequency], 
              name: 'idx_schedules_variant_stop_day_freq'
    add_index :bus_schedules, [:bus_stop_id, :day_type, :scheduled_time],
              name: 'idx_schedules_stop_day_time'
    add_index :bus_schedules, :day_type
  end
end

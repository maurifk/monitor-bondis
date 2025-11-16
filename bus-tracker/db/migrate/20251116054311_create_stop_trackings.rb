class CreateStopTrackings < ActiveRecord::Migration[8.0]
  def change
    create_table :stop_trackings do |t|
      t.references :bus_stop, null: false, foreign_key: true
      t.text :lines
      t.text :line_variant_ids
      t.boolean :active, default: true, null: false
      t.datetime :started_at
      t.datetime :last_job_run_at

      t.timestamps
    end
    
    add_index :stop_trackings, [:bus_stop_id, :active]
  end
end

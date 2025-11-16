class CreateLines < ActiveRecord::Migration[8.0]
  def change
    create_table :lines do |t|
      t.string :line_number, null: false
      t.string :name
      t.integer :api_line_id

      t.timestamps
    end
    
    add_index :lines, :line_number, unique: true
    add_index :lines, :api_line_id, unique: true
  end
end

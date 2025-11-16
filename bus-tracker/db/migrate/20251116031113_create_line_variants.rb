class CreateLineVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :line_variants do |t|
      t.references :line, null: false, foreign_key: true
      t.string :line_number, null: false
      t.string :origin, null: false
      t.string :destination, null: false
      t.string :subline
      t.boolean :special, default: false, null: false
      t.integer :api_line_variant_id, null: false

      t.timestamps
    end
    
    add_index :line_variants, :api_line_variant_id, unique: true
    add_index :line_variants, :line_number
  end
end

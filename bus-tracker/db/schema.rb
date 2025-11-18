# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_11_16_054311) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bus_passages", force: :cascade do |t|
    t.bigint "bus_stop_id", null: false
    t.string "line", null: false
    t.string "destination"
    t.string "bus_code"
    t.decimal "bus_latitude", precision: 10, scale: 8
    t.decimal "bus_longitude", precision: 11, scale: 8
    t.datetime "detected_at", null: false
    t.integer "eta_minutes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bus_stop_id", "detected_at"], name: "index_bus_passages_on_bus_stop_id_and_detected_at"
    t.index ["bus_stop_id"], name: "index_bus_passages_on_bus_stop_id"
    t.index ["detected_at"], name: "index_bus_passages_on_detected_at"
    t.index ["line"], name: "index_bus_passages_on_line"
  end

  create_table "bus_positions", force: :cascade do |t|
    t.bigint "bus_tracking_id", null: false
    t.decimal "latitude", precision: 10, scale: 7, null: false
    t.decimal "longitude", precision: 10, scale: 7, null: false
    t.decimal "distance_to_stop", precision: 10, scale: 2, null: false
    t.integer "speed"
    t.datetime "api_timestamp", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_timestamp"], name: "index_bus_positions_on_api_timestamp"
    t.index ["bus_tracking_id", "api_timestamp"], name: "idx_bus_positions_tracking_time"
    t.index ["bus_tracking_id"], name: "index_bus_positions_on_bus_tracking_id"
  end

  create_table "bus_schedules", force: :cascade do |t|
    t.bigint "line_variant_id", null: false
    t.bigint "bus_stop_id", null: false
    t.integer "day_type", null: false, comment: "1=Hábil, 2=Sábado, 3=Domingo"
    t.integer "frequency", null: false, comment: "Hora de salida en formato hmm0"
    t.integer "ordinal", null: false, comment: "Número ordinal de parada en recorrido"
    t.integer "scheduled_time", null: false, comment: "Hora de pasada en formato hmm"
    t.string "previous_day", limit: 1, default: "N", null: false, comment: "N=mismo día, S=día anterior, *=especial"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bus_stop_id", "day_type", "scheduled_time"], name: "idx_schedules_stop_day_time"
    t.index ["bus_stop_id"], name: "index_bus_schedules_on_bus_stop_id"
    t.index ["day_type"], name: "index_bus_schedules_on_day_type"
    t.index ["line_variant_id", "bus_stop_id", "day_type", "frequency"], name: "idx_schedules_variant_stop_day_freq"
    t.index ["line_variant_id"], name: "index_bus_schedules_on_line_variant_id"
  end

  create_table "bus_stops", force: :cascade do |t|
    t.integer "busstop_id", null: false
    t.string "street1"
    t.string "street2"
    t.integer "street1_id"
    t.integer "street2_id"
    t.decimal "latitude", precision: 10, scale: 8, null: false
    t.decimal "longitude", precision: 11, scale: 8, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["busstop_id"], name: "index_bus_stops_on_busstop_id", unique: true
    t.index ["latitude", "longitude"], name: "index_bus_stops_on_latitude_and_longitude"
  end

  create_table "bus_trackings", force: :cascade do |t|
    t.bigint "bus_stop_id", null: false
    t.integer "bus_id", null: false
    t.string "line", null: false
    t.integer "line_variant_id"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.decimal "distance_to_stop", precision: 10, scale: 2
    t.integer "speed"
    t.datetime "api_timestamp"
    t.datetime "last_seen_at"
    t.boolean "tracking_active", default: true, null: false
    t.integer "missing_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bus_stop_id", "bus_id"], name: "idx_bus_trackings_stop_bus"
    t.index ["bus_stop_id", "tracking_active"], name: "idx_bus_trackings_stop_active"
    t.index ["bus_stop_id"], name: "index_bus_trackings_on_bus_stop_id"
    t.index ["last_seen_at"], name: "index_bus_trackings_on_last_seen_at"
  end

  create_table "line_variants", force: :cascade do |t|
    t.bigint "line_id", null: false
    t.string "line_number", null: false
    t.string "origin", null: false
    t.string "destination", null: false
    t.string "subline"
    t.boolean "special", default: false, null: false
    t.integer "api_line_variant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_line_variant_id"], name: "index_line_variants_on_api_line_variant_id", unique: true
    t.index ["line_id"], name: "index_line_variants_on_line_id"
    t.index ["line_number"], name: "index_line_variants_on_line_number"
  end

  create_table "lines", force: :cascade do |t|
    t.string "line_number", null: false
    t.string "name"
    t.integer "api_line_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["api_line_id"], name: "index_lines_on_api_line_id", unique: true
    t.index ["line_number"], name: "index_lines_on_line_number", unique: true
  end

  create_table "stop_trackings", force: :cascade do |t|
    t.bigint "bus_stop_id", null: false
    t.text "lines"
    t.text "line_variant_ids"
    t.boolean "active", default: true, null: false
    t.datetime "started_at"
    t.datetime "last_job_run_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bus_stop_id", "active"], name: "index_stop_trackings_on_bus_stop_id_and_active"
    t.index ["bus_stop_id"], name: "index_stop_trackings_on_bus_stop_id"
  end

  add_foreign_key "bus_passages", "bus_stops"
  add_foreign_key "bus_positions", "bus_trackings"
  add_foreign_key "bus_schedules", "bus_stops"
  add_foreign_key "bus_schedules", "line_variants"
  add_foreign_key "bus_trackings", "bus_stops"
  add_foreign_key "line_variants", "lines"
  add_foreign_key "stop_trackings", "bus_stops"
end

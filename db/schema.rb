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

ActiveRecord::Schema[8.1].define(version: 2026_11_25_180000) do
  create_table "events", force: :cascade do |t|
    t.integer "source_id", null: false
    t.string "idempotency_key", null: false
    t.string "event_type", null: false
    t.text "payload", null: false
    t.datetime "received_at", null: false
    t.index ["source_id", "idempotency_key"], name: "index_events_on_source_id_and_idempotency_key", unique: true
  end

  create_table "sources", force: :cascade do |t|
    t.string "name", null: false
    t.string "token_digest", null: false
    t.text "signing_secret", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_sources_on_token_digest", unique: true
  end

  add_foreign_key "events", "sources"
end

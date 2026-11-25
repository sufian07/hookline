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

ActiveRecord::Schema[8.1].define(version: 2026_11_25_181000) do
  create_table "deliveries", force: :cascade do |t|
    t.integer "event_id", null: false
    t.integer "subscription_id", null: false
    t.string "status", default: "pending", null: false
    t.integer "attempts_count", default: 0, null: false
    t.datetime "next_attempt_at", null: false
    t.datetime "claimed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "subscription_id"], name: "index_deliveries_on_event_id_and_subscription_id", unique: true
    t.index ["status", "next_attempt_at"], name: "index_deliveries_on_status_and_next_attempt_at"
    t.index ["subscription_id"], name: "index_deliveries_on_subscription_id"
    t.check_constraint "status IN ('pending', 'delivering', 'delivered', 'dead')", name: "deliveries_status"
  end

  create_table "delivery_attempts", force: :cascade do |t|
    t.integer "delivery_id", null: false
    t.integer "number", null: false
    t.integer "response_code"
    t.string "error"
    t.integer "duration_ms", null: false
    t.datetime "created_at", null: false
    t.index ["delivery_id", "number"], name: "index_delivery_attempts_on_delivery_id_and_number", unique: true
  end

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

  create_table "subscriptions", force: :cascade do |t|
    t.integer "source_id", null: false
    t.string "url", null: false
    t.string "event_filter"
    t.text "signing_secret", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_id"], name: "index_subscriptions_on_source_id"
  end

  add_foreign_key "deliveries", "events"
  add_foreign_key "deliveries", "subscriptions"
  add_foreign_key "delivery_attempts", "deliveries"
  add_foreign_key "events", "sources"
  add_foreign_key "subscriptions", "sources"
end

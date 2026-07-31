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

ActiveRecord::Schema[8.0].define(version: 2026_07_30_150744) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "bookings", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.bigint "user_id", null: false
    t.bigint "service_id", null: false
    t.date "date"
    t.time "time"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_bookings_on_business_id"
    t.index ["service_id"], name: "index_bookings_on_service_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "business_booking_settings", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.integer "booking_interval_minutes", default: 30, null: false
    t.integer "minimum_notice_minutes", default: 240, null: false
    t.integer "advance_booking_days", default: 30, null: false
    t.integer "buffer_minutes", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_business_booking_settings_on_business", unique: true
    t.index ["business_id"], name: "index_business_booking_settings_on_business_id"
  end

  create_table "business_opening_hour_breaks", force: :cascade do |t|
    t.bigint "business_opening_hour_id", null: false
    t.time "starts_at"
    t.time "ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_opening_hour_id"], name: "index_business_opening_hour_breaks_on_business_opening_hour_id"
  end

  create_table "business_opening_hours", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.integer "day_of_week"
    t.boolean "open"
    t.time "opens_at"
    t.time "closes_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_business_opening_hours_on_business_id"
  end

  create_table "business_settings", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.string "business_name"
    t.string "business_category"
    t.string "phone_number"
    t.string "business_email"
    t.text "business_description"
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "town_or_city"
    t.string "postcode"
    t.string "country"
    t.boolean "booking_page_live", default: false
    t.boolean "automatically_confirm_bookings", default: true
    t.boolean "allow_customer_cancellations", default: true
    t.boolean "require_customer_phone_number", default: false
    t.integer "cancellation_notice_hours", default: 24
    t.boolean "new_booking_notifications", default: true
    t.boolean "cancellation_notifications", default: true
    t.boolean "daily_appointment_summary", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.index ["business_id"], name: "index_business_settings_on_business_id"
  end

  create_table "businesses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "business_name"
    t.string "page_address"
    t.string "category"
    t.string "phone_number"
    t.jsonb "address", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_businesses_on_user_id"
  end

  create_table "customer_settings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.date "date_of_birth"
    t.string "preferred_name"
    t.string "phone_number"
    t.string "preferred_contact_method"
    t.string "address_line_1"
    t.string "address_line_2"
    t.string "town_or_city"
    t.string "postcode"
    t.string "country"
    t.boolean "booking_confirmations", default: true, null: false
    t.boolean "appointment_reminders", default: true, null: false
    t.boolean "booking_changes", default: true, null: false
    t.boolean "offers_and_service_updates", default: false, null: false
    t.string "reminder_timing"
    t.string "reminder_method"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.index ["user_id"], name: "index_customer_settings_on_user_id"
  end

  create_table "jwt_denylists", force: :cascade do |t|
    t.string "jti"
    t.datetime "exp"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["jti"], name: "index_jwt_denylists_on_jti"
  end

  create_table "services", force: :cascade do |t|
    t.bigint "business_id", null: false
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "minutes_duration", null: false
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_id"], name: "index_services_on_business_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 2, null: false
    t.string "first_name"
    t.string "last_name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "bookings", "businesses"
  add_foreign_key "bookings", "services"
  add_foreign_key "bookings", "users"
  add_foreign_key "business_booking_settings", "businesses"
  add_foreign_key "business_opening_hour_breaks", "business_opening_hours"
  add_foreign_key "business_opening_hours", "businesses"
  add_foreign_key "business_settings", "businesses"
  add_foreign_key "businesses", "users"
  add_foreign_key "customer_settings", "users"
  add_foreign_key "services", "businesses"
end

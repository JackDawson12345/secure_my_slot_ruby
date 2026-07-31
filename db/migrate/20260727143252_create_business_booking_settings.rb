class CreateBusinessBookingSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :business_booking_settings do |t|
      t.references :business, null: false, foreign_key: true

      t.integer :booking_interval_minutes, null: false, default: 30
      t.integer :minimum_notice_minutes, null: false, default: 240
      t.integer :advance_booking_days, null: false, default: 30
      t.integer :buffer_minutes, null: false, default: 0

      t.timestamps
    end

    add_index :business_booking_settings,
              :business_id,
              unique: true,
              name: "index_business_booking_settings_on_business"
  end
end
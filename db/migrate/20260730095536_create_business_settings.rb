class CreateBusinessSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :business_settings do |t|
      t.references :business, null: false, foreign_key: true
      t.string :business_name
      t.string :business_category
      t.string :phone_number
      t.string :business_email
      t.text :business_description
      t.string :address_line_1
      t.string :address_line_2
      t.string :town_or_city
      t.string :postcode
      t.string :country
      t.boolean :booking_page_live, default: false
      t.boolean :automatically_confirm_bookings, default: true
      t.boolean :allow_customer_cancellations, default: true
      t.boolean :require_customer_phone_number, default: false
      t.integer :cancellation_notice_hours, default: 24
      t.boolean :new_booking_notifications, default: true
      t.boolean :cancellation_notifications, default: true
      t.boolean :daily_appointment_summary, default: false

      t.timestamps
    end
  end
end

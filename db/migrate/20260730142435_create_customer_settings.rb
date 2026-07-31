class CreateCustomerSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :customer_settings do |t|
      t.references :user, null: false, foreign_key: true

      t.date :date_of_birth
      t.string :preferred_name
      t.string :phone_number
      t.string :preferred_contact_method

      t.string :address_line_1
      t.string :address_line_2
      t.string :town_or_city
      t.string :postcode
      t.string :country

      t.boolean :booking_confirmations, default: true, null: false
      t.boolean :appointment_reminders, default: true, null: false
      t.boolean :booking_changes, default: true, null: false
      t.boolean :offers_and_service_updates, default: false, null: false

      t.string :reminder_timing
      t.string :reminder_method

      t.timestamps
    end
  end
end
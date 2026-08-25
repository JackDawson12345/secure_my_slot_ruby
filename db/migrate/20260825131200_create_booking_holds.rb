class CreateBookingHolds < ActiveRecord::Migration[8.0]
  def change
    create_table :booking_holds do |t|
      t.references :business, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.references :booking,
                   null: true,
                   foreign_key: true

      t.date :date, null: false
      t.time :time, null: false

      t.text :notes

      t.string :stripe_checkout_session_id

      t.datetime :expires_at, null: false
      t.datetime :completed_at

      t.timestamps
    end

    add_index :booking_holds,
              :stripe_checkout_session_id,
              unique: true

    add_index :booking_holds,
              [:business_id, :service_id, :date, :time],
              name: "index_booking_holds_on_slot"
  end
end
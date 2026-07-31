class AddStripePaymentFieldsToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings,
               :payment_status,
               :string,
               default: "not_required",
               null: false

    add_column :bookings,
               :stripe_checkout_session_id,
               :string

    add_column :bookings,
               :stripe_payment_intent_id,
               :string

    add_index :bookings,
              :stripe_checkout_session_id,
              unique: true

    add_index :bookings,
              :stripe_payment_intent_id,
              unique: true
  end
end
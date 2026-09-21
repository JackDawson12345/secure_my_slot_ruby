class AddPaymentLinkStripeFieldsToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :payment_link_checkout_session_id, :string
    add_column :bookings, :payment_link_payment_intent_id, :string
  end
end

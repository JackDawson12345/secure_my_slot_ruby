class AddNoShowPaymentFieldsToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :no_show_fee, :decimal
    add_column :bookings, :no_show_payment_intent_id, :string
    add_column :bookings, :no_show_fee_charged_at, :datetime
  end
end

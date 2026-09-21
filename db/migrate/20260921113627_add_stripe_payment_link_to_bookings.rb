class AddStripePaymentLinkToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :stripe_payment_link, :string
  end
end

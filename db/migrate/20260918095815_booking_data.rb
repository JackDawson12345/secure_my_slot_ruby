class BookingData < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :coupon, :string
    add_column :bookings, :amount, :decimal
  end
end

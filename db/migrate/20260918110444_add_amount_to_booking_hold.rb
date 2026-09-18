class AddAmountToBookingHold < ActiveRecord::Migration[8.0]
  def change
    add_column :booking_holds, :coupon, :string
    add_column :booking_holds, :amount, :decimal
  end
end

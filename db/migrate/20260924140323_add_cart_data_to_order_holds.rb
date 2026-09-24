class AddCartDataToOrderHolds < ActiveRecord::Migration[8.0]
  def change
    add_column :order_holds, :cart_data, :jsonb
  end
end

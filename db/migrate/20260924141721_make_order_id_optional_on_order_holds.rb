class MakeOrderIdOptionalOnOrderHolds < ActiveRecord::Migration[8.0]
  def change
    change_column_null :order_holds, :order_id, true
  end
end
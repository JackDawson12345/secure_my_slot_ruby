class AddPublicIdToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :public_id, :uuid
  end
end

class AddBillingAddressToOrder < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :address_line_1, :string
    add_column :orders, :address_line_2, :string
    add_column :orders, :town, :string
    add_column :orders, :postcode, :string

    add_column :order_holds, :address_line_1, :string
    add_column :order_holds, :address_line_2, :string
    add_column :order_holds, :town, :string
    add_column :order_holds, :postcode, :string
  end
end

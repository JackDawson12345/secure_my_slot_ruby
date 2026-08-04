class AddDepositToServices < ActiveRecord::Migration[8.0]
  def change
    add_column :services, :deposit_enabled, :boolean, default: false, null: false
    add_column :services, :deposit, :decimal, precision: 10, scale: 2
  end
end
class AddCoordinatesToBusinessAndCustomerSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :business_settings, :latitude, :decimal,
               precision: 10,
               scale: 7

    add_column :business_settings, :longitude, :decimal,
               precision: 10,
               scale: 7

    add_column :customer_settings, :latitude, :decimal,
               precision: 10,
               scale: 7

    add_column :customer_settings, :longitude, :decimal,
               precision: 10,
               scale: 7
  end
end
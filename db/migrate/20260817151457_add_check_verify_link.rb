class AddCheckVerifyLink < ActiveRecord::Migration[8.0]
  def change
    add_column :business_settings, :check_verify_link, :string
  end
end

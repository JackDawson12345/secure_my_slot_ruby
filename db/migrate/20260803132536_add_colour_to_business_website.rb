class AddColourToBusinessWebsite < ActiveRecord::Migration[8.0]
  def change
    add_column :business_websites, :colour, :string, default: "blue", null: false
  end
end

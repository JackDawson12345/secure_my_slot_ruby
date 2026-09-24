class AddPublishingFieldsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :visibility, :string, default: "public"
    add_column :products, :publish_at, :datetime
    add_column :products, :product_tabs, :text
  end
end

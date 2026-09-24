class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.references :business, null: false, foreign_key: true

      t.string :name, null: false
      t.text :description
      t.text :short_description

      t.decimal :regular_price, precision: 10, scale: 2
      t.decimal :sale_price, precision: 10, scale: 2

      t.string :sku
      t.string :status, default: "draft"
      t.string :slug

      t.boolean :featured, default: false
      t.boolean :manage_stock, default: false
      t.integer :stock_count, default: 0

      t.timestamps
    end

    add_index :products, :slug, unique: true
    add_index :products, :sku, unique: true
  end
end
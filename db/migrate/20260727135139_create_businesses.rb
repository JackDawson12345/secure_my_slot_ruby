class CreateBusinesses < ActiveRecord::Migration[8.0]
  def change
    create_table :businesses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :business_name
      t.string :page_address
      t.string :category
      t.string :phone_number

      t.jsonb :address, null: false, default: {}

      t.timestamps
    end
  end
end
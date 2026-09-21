class CreateBusinessCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :business_customers do |t|
      t.references :business, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :stripe_customer_id

      t.timestamps
    end

    add_index :business_customers,
              [:business_id, :user_id],
              unique: true
  end
end

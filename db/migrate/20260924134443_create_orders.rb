class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :business, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status
      t.string :payment_method
      t.string :payment_status
      t.string :stripe_checkout_session_id
      t.string :stripe_payment_intent_id
      t.decimal :amount

      t.timestamps
    end
  end
end

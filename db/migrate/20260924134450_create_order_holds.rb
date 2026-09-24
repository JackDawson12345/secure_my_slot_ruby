class CreateOrderHolds < ActiveRecord::Migration[8.0]
  def change
    create_table :order_holds do |t|
      t.references :business, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :amount
      t.datetime :expires_at
      t.string :stripe_checkout_session_id

      t.timestamps
    end
  end
end

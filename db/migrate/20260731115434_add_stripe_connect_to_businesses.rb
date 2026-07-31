class AddStripeConnectToBusinesses < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :stripe_account_id, :string

    add_column :businesses,
               :stripe_details_submitted,
               :boolean,
               default: false,
               null: false

    add_column :businesses,
               :stripe_charges_enabled,
               :boolean,
               default: false,
               null: false

    add_column :businesses,
               :stripe_payouts_enabled,
               :boolean,
               default: false,
               null: false

    add_index :businesses,
              :stripe_account_id,
              unique: true
  end
end
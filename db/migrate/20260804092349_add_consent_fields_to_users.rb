class AddConsentFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users,
               :terms_accepted,
               :boolean,
               default: false,
               null: false

    add_column :users,
               :terms_accepted_at,
               :datetime

    add_column :users,
               :marketing_consent,
               :boolean,
               default: false,
               null: false
  end
end
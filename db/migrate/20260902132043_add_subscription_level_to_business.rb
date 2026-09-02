class AddSubscriptionLevelToBusiness < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :subscription_level, :integer, default: 0
  end
end

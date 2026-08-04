class AddSubscribedToBusiness < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :subscribed, :boolean, default: false
  end
end

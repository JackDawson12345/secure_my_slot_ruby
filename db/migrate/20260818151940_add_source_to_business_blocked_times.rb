class AddSourceToBusinessBlockedTimes < ActiveRecord::Migration[8.0]
  def change
    add_column :business_blocked_times, :source, :string
    add_column :business_blocked_times, :external_id, :string
  end
end

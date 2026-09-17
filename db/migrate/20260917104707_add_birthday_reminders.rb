class AddBirthdayReminders < ActiveRecord::Migration[8.0]
  def change
    add_column :business_settings, :birthday_reminder, :boolean, default: false
  end
end

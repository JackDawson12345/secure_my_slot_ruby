class AddIconToServices < ActiveRecord::Migration[8.0]
  def change
    add_column :services, :icon, :string, default: "calendar-check", null: false
  end
end
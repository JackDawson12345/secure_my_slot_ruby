class CreateBirthdayReminderMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :birthday_reminder_messages do |t|
      t.references :business, null: false, foreign_key: true
      t.text :text

      t.timestamps
    end
  end
end
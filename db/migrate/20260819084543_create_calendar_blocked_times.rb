class CreateCalendarBlockedTimes < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_blocked_times do |t|
      t.references :business, null: false, foreign_key: true
      t.references :calendar_connection, null: false, foreign_key: true
      t.string :title
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :all_day
      t.string :source
      t.string :external_id
      t.text :notes

      t.timestamps
    end
  end
end

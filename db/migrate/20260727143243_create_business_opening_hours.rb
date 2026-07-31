class CreateBusinessOpeningHours < ActiveRecord::Migration[8.0]
  def change
    create_table :business_opening_hours do |t|
      t.references :business, null: false, foreign_key: true
      t.integer :day_of_week, null: false
      t.boolean :open, null: false, default: false
      t.time :opens_at
      t.time :closes_at

      t.timestamps
    end

    add_index :business_opening_hours,
              [:business_id, :day_of_week],
              unique: true,
              name: "index_business_opening_hours_on_business_and_day"
  end
end
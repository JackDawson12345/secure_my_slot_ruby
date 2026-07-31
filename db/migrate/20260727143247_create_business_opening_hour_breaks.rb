class CreateBusinessOpeningHourBreaks < ActiveRecord::Migration[8.0]
  def change
    create_table :business_opening_hour_breaks do |t|
      t.references :business_opening_hour,
                   null: false,
                   foreign_key: true,
                   index: { name: "index_opening_hour_breaks_on_opening_hour" }

      t.time :starts_at, null: false
      t.time :ends_at, null: false

      t.timestamps
    end
  end
end
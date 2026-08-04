class CreateBusinessBlockedTimes < ActiveRecord::Migration[8.0]
  def change
    create_table :business_blocked_times do |t|
      t.references :business, null: false, foreign_key: true
      t.string :title, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.boolean :all_day, null: false, default: false
      t.text :notes

      t.timestamps
    end

    add_index :business_blocked_times,
              [:business_id, :starts_at, :ends_at],
              name: "index_business_blocked_times_on_period"
  end
end
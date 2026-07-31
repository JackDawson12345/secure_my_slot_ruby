class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.references :business, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.date :date
      t.time :time
      t.string :status

      t.timestamps
    end
  end
end

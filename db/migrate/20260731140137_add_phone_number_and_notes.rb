class AddPhoneNumberAndNotes < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :phone_number, :string
    add_column :bookings, :notes, :text
  end
end

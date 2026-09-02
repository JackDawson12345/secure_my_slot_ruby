class AddConsultationTokenToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :consultation_token, :string

    add_index :bookings,
              :consultation_token,
              unique: true
  end
end

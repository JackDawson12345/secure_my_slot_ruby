class AddConsultationResponsesToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings,
               :consultation_responses,
               :jsonb,
               null: false,
               default: {}
  end
end

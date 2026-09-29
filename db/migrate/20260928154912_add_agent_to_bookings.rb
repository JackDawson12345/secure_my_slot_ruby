class AddAgentToBookings < ActiveRecord::Migration[8.0]
  def change
    add_reference :bookings,
                  :agent,
                  null: true,
                  foreign_key: { to_table: :users }
  end
end

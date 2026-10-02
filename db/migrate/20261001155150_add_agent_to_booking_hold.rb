class AddAgentToBookingHold < ActiveRecord::Migration[8.0]
  def change
    add_column :booking_holds, :agent_id, :uuid
  end
end

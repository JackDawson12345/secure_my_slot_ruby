class FixAgentIdTypeOnBookingHolds < ActiveRecord::Migration[8.0]
  def change
    remove_column :booking_holds, :agent_id, :uuid

    add_reference :booking_holds,
                  :agent,
                  type: :integer,
                  null: true,
                  foreign_key: { to_table: :users }
  end
end

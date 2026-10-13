class AddSalesAgentToBusiness < ActiveRecord::Migration[8.0]
  def change
    add_column :businesses, :sales_agent_id, :integer

    add_index :businesses, :sales_agent_id
  end
end

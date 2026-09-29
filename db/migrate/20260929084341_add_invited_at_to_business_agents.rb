class AddInvitedAtToBusinessAgents < ActiveRecord::Migration[8.0]
  def change
    add_column :business_agents, :invited_at, :datetime
  end
end

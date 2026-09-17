class AddUserAgentToAgreementStatuses < ActiveRecord::Migration[8.0]
  def change
    add_column :agreement_statuses, :user_agent, :text
  end
end

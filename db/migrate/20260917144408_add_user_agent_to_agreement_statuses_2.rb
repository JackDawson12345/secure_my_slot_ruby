class AddUserAgentToAgreementStatuses2 < ActiveRecord::Migration[8.0]
  def change
    add_column :agreement_statuses, :device, :text
  end
end

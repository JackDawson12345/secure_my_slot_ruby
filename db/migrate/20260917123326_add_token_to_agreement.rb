class AddTokenToAgreement < ActiveRecord::Migration[8.0]
  def change
    add_column :agreement_statuses, :token, :string
  end
end

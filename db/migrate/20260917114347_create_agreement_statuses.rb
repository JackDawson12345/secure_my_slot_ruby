class CreateAgreementStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :agreement_statuses do |t|
      t.references :business, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true
      t.references :agreement, null: false, foreign_key: true
      t.string :status
      t.datetime :signed_at
      t.string :ip_address

      t.timestamps
    end
  end
end

class CreateAgreementSignatures < ActiveRecord::Migration[8.0]
  def change
    create_table :agreement_signatures do |t|
      t.references :agreement_status, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end

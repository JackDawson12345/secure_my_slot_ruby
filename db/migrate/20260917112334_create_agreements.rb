class CreateAgreements < ActiveRecord::Migration[8.0]
  def change
    create_table :agreements do |t|
      t.references :business, null: false, foreign_key: true
      t.string :name
      t.text :content

      t.timestamps
    end
  end
end

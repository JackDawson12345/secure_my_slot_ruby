class CreateBusinessAgents < ActiveRecord::Migration[8.0]
  def change
    create_table :business_agents do |t|
      t.references :business, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end

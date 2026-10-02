class CreateServiceAgents < ActiveRecord::Migration[8.0]
  def change
    create_table :service_agents do |t|
      t.references :service, null: false, foreign_key: true
      t.references :business_agent, null: false, foreign_key: true

      t.timestamps
    end
  end
end

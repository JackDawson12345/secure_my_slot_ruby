class CreateBusinessAgentSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :business_agent_settings do |t|
      t.references :business, null: false, foreign_key: true

      t.integer :agent_selection, null: false, default: 0
      t.integer :booking_visibility, null: false, default: 0
      t.boolean :allow_reassignment, null: false, default: true

      t.timestamps
    end

    add_index :business_agent_settings,
              :business_id,
              unique: true,
              name: "index_business_agent_settings_on_business_unique"
  end
end

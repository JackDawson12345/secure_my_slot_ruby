class AddDescriptionToAgent < ActiveRecord::Migration[8.0]
  def change
    add_column :business_agents, :description, :text
  end
end
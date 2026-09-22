class CreateSocialPostTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :social_post_templates do |t|
      t.string :name
      t.string :slug
      t.string :category
      t.text :description
      t.string :status
      t.string :template_key
      t.jsonb :fields
      t.jsonb :settings

      t.timestamps
    end
  end
end

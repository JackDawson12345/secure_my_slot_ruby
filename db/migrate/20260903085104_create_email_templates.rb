class CreateEmailTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :email_templates do |t|
      t.references :business, null: false, foreign_key: true
      t.string :template_type
      t.string :subject
      t.text :body

      t.timestamps
    end
  end
end

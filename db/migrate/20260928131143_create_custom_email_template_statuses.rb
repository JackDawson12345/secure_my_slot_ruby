class CreateCustomEmailTemplateStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :custom_email_template_statuses do |t|
      t.references :business, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true
      t.references :email_template, null: false, foreign_key: true
      t.string :status
      t.string :token

      t.timestamps
    end
  end
end

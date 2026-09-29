class UpdateEmailTempaltes < ActiveRecord::Migration[8.0]
  def change
    add_column :email_templates, :custom, :boolean, default: false
  end
end

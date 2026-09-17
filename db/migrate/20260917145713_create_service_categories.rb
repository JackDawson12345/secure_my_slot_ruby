class CreateServiceCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :service_categories do |t|
      t.references :business, null: false, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end

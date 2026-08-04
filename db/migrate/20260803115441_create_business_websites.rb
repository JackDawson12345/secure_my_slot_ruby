class CreateBusinessWebsites < ActiveRecord::Migration[8.0]
  def change
    create_table :business_websites do |t|
      t.references :business, null: false, foreign_key: true

      t.jsonb :hero, null: false, default: {}
      t.jsonb :services, null: false, default: {}
      t.jsonb :about_us, null: false, default: {}
      t.jsonb :visit, null: false, default: {}

      t.timestamps
    end
  end
end
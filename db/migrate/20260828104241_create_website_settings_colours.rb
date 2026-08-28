class CreateWebsiteSettingsColours < ActiveRecord::Migration[8.0]
  def change
    create_table :website_settings_colours do |t|
      t.references :business, null: false, foreign_key: true
      t.references :business_website, null: false, foreign_key: true

      t.string :hex_code, null: false
      t.string :colour_900, null: false
      t.string :colour_700, null: false
      t.string :colour_500, null: false
      t.string :colour_300, null: false

      t.timestamps
    end

  end
end
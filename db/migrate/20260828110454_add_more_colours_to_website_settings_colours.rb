class AddMoreColoursToWebsiteSettingsColours < ActiveRecord::Migration[8.0]
  def change
    add_column :website_settings_colours, :colour_50, :string
    add_column :website_settings_colours, :colour_100, :string
    add_column :website_settings_colours, :colour_200, :string
    add_column :website_settings_colours, :colour_400, :string
    add_column :website_settings_colours, :colour_600, :string
    add_column :website_settings_colours, :colour_800, :string
    add_column :website_settings_colours, :colour_950, :string
  end
end

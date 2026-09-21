class AddDeviceAndTrafficSourceToPageViews < ActiveRecord::Migration[8.0]
  def change
    add_column :page_views, :device_type, :string
    add_column :page_views, :traffic_source, :string
  end
end

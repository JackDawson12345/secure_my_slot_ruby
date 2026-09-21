class CreatePageViews < ActiveRecord::Migration[8.0]
  def change
    create_table :page_views do |t|
      t.references :pageable, polymorphic: true, null: false
      t.string :visitor_id
      t.string :ip_address
      t.text :user_agent
      t.string :referrer

      t.timestamps
    end
  end
end

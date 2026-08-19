class CreateCalendarConnections < ActiveRecord::Migration[8.0]
  def change
    create_table :calendar_connections do |t|

      t.references :business, null: false

      t.string :provider

      t.string :email

      t.text :access_token
      t.text :refresh_token

      t.datetime :expires_at

      t.string :calendar_id

      t.datetime :last_synced_at

      t.boolean :active, default: true

      t.timestamps

    end
  end
end

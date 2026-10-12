class CreatePushTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :push_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.string :platform, null: false

      t.timestamps
    end

    add_index :push_tokens, :token, unique: true
  end
end
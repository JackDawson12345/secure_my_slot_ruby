class CreateSocialPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :social_posts do |t|
      t.references :business, null: false, foreign_key: true
      t.references :social_post_template, null: false, foreign_key: true
      t.string :title
      t.string :status
      t.jsonb :content
      t.jsonb :settings
      t.text :caption

      t.timestamps
    end
  end
end

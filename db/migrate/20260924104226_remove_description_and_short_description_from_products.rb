class RemoveDescriptionAndShortDescriptionFromProducts < ActiveRecord::Migration[8.0]
  def change

    remove_column :products, :description, :text
    remove_column :products, :short_description, :text

  end
end

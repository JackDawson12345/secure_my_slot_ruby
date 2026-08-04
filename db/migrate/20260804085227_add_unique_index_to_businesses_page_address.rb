class AddUniqueIndexToBusinessesPageAddress < ActiveRecord::Migration[8.0]
  def change
    add_index :businesses,
              "LOWER(page_address)",
              unique: true,
              name: "index_businesses_on_lower_page_address"
  end
end
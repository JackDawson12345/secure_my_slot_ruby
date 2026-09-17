class AddServiceCategoryToServices < ActiveRecord::Migration[8.0]
  def change
    add_reference :services, :service_category, foreign_key: true
  end
end

class CreateServiceCoupons < ActiveRecord::Migration[8.0]
  def change
    create_table :service_coupons do |t|
      t.references :business, null: false, foreign_key: true
      t.string :name
      t.string :code
      t.string :coupon_type
      t.decimal :discount
      t.json :services
      t.boolean :active
      t.datetime :expires_at

      t.timestamps
    end
  end
end

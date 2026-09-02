class CreateConsultationForms < ActiveRecord::Migration[8.0]
  def change
    create_table :consultation_forms do |t|
      t.string :name, null: false

      t.jsonb :structure,
              null: false,
              default: []

      t.references :business,
                   null: false,
                   foreign_key: true

      t.timestamps
    end
  end
end

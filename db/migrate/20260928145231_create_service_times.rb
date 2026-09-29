class CreateServiceTimes < ActiveRecord::Migration[8.0]
  def change
    create_table :service_times do |t|
      t.references :service, null: false, foreign_key: true
      t.time :start_time
      t.time :end_time

      t.timestamps
    end
  end
end

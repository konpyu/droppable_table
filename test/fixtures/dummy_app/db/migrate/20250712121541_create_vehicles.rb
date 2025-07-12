class CreateVehicles < ActiveRecord::Migration[8.0]
  def change
    create_table :vehicles do |t|
      t.string :name
      t.string :type

      t.timestamps
    end
  end
end

class CreateLegacyData < ActiveRecord::Migration[8.0]
  def change
    create_table :legacy_data do |t|
      t.text :content

      t.timestamps
    end
  end
end

# frozen_string_literal: true

class CreateCustomNamedTable < ActiveRecord::Migration[8.0]
  def change
    create_table :custom_named_table do |t|
      t.string :name

      t.timestamps
    end
  end
end

# frozen_string_literal: true

class CreateAbandonedLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :abandoned_logs do |t|
      t.text :message

      t.timestamps
    end
  end
end

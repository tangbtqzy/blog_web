class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.integer :user
      t.string :title
      t.text :description
      t.integer :level

      t.timestamps
    end
  end
end

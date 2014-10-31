class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.string :title
      t.text :content
      t.string :email
      t.string :phone

      t.timestamps
    end
  end
end

class CreateBannerManages < ActiveRecord::Migration
  def change
    create_table :banner_manages, id: :uuid do |t|
      t.string :img_url
      t.string :page_routes
      t.string :title
      t.string :link_url
      t.integer :width
      t.integer :height

      t.timestamps
    end
  end
end

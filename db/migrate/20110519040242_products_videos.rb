class ProductsVideos < ActiveRecord::Migration
  def self.up
    create_table :products_videos, :id => false do |t|
  		t.column :product_id, :integer, :null => false
  		t.column :video_id, :integer, :null => false
		end
  end

  def self.down
    drop_table :products_videos
  end
end
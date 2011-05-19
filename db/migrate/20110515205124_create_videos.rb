class CreateVideos < ActiveRecord::Migration
  def self.up
    create_table :videos do |t|
      t.string :name
      t.text :description
      t.string :url
      t.timestamp :publish_up
      t.timestamp :publish_down

      t.timestamps
    end
  end

  def self.down
    drop_table :videos
  end
end

class Package < ActiveRecord::Migration
  def self.up
    create_table :packages do |t|
      t.integer :product_id
    end
  end

  def self.down
    drop_table :packages
  end
end

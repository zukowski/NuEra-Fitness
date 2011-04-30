class AddProductIdToPackages < ActiveRecord::Migration
  def self.up
    add_column :packages, :product_id, :integer
  end

  def self.down
    remove_column :packages, :product_id
  end
end

class AddSupplierIdToShipment < ActiveRecord::Migration
  def self.up
    add_column :shipments, :supplier_id, :integer
  end

  def self.down
    remove_column :shipments, :supplier_id
  end
end

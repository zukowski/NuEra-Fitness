class AddShipmentIdToLineItems < ActiveRecord::Migration
  def self.up
    add_column :line_items, :shipment_id, :integer
  end

  def self.down
    remove_column :line_items, :shipment_id
  end
end

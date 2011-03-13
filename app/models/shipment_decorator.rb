Shipment.class_eval do
  belongs_to :supplier

  def line_items
    if order.complete? and Spree::Config[:track_inventory_levels]
      order.line_items_for_supplier(supplier).select {|li| inventory_units.map(&:variant_id).include(li.variant_id)}
    else
      order.line_items_for_supplier(supplier)
    end
  end
end

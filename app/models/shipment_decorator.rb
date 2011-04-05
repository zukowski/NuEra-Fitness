Shipment.class_eval do
  belongs_to :supplier
  
  Shipment.state_machines[:state] = StateMachine::Machine.new(Shipment, :initial => 'pending', :use_transactions => false) do
    event(:quote) { transition :pending => :quote }
    event(:ready) { transition :pending => :ready }
    event(:pend)  { transition :ready   => :pending }
    event(:ship)  { transition :ready   => :shipped }

    after_transition :to => :shipped, :do => :after_ship
  end

  def line_items
    if order.complete? and Spree::Config[:track_inventory_levels]
      order.line_items_for_supplier(supplier).select {|li| inventory_units.map(&:variant_id).include(li.variant_id)}
    else
      order.line_items_for_supplier(supplier)
    end
  end

  private

  def determine_state(order)
    return 'quote'   if adjustment.amount == 0
    return 'pending' if self.inventory_units.any? {|unit| unit.backordered?}
    return 'shipped' if state == 'shipped'
    order.payment_state == 'balance_due' ? 'pending' : 'ready'
  end
end

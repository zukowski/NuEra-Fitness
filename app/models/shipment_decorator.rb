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
      order.line_items_for_supplier(self.supplier).select do |li|
        inventory_units.map(&:variant_id).include?(li.variant_id)
      end
    else
      order.line_items_for_supplier(self.supplier)
    end
  end

  # A shipment is required within an order if there are line_items that exist
  # for the shipment, order there is a package in the order that will create
  # inventory units for this shipment
  def is_required?
    order.suppliers.any? {|supplier| supplier == self.supplier}
  end

  def needs_quote?
    # We need a quote if there are line items that total over 150 lbs
    return false unless adjustment.nil? or adjustment.amount == 0.0
    order.weight_of_line_items_for_supplier(supplier) > 150
  end

  def update!(order)
    # Check to see if any of the line_items have been changed for this update
    new_shipping_method = ShippingMethod.all_available(order, :front_end, :supplier => supplier).first
    unless new_shipping_method == shipping_method
      update_attribute_without_callbacks(:shipping_method_id, new_shipping_method.id)
      # If we changed from UPS to Freight, than any possible adjustment needs to be reset
      # If the change was from Freight to UPS, then Order#update_adjustments will take
      # care of the udpate
      adjustment.update_attribute(:originator, new_shipping_method)
      if new_shipping_method.calculator.type =~ /Freight/
        adjustment.update_attribute(:amount, 0)
      end
    end
    old_state = self.state
    new_state = determine_state(order)
    update_attributes_without_callbacks(:state => new_state)
    after_ship if new_state == 'shipped' && old_state != 'shipped'
  end

  private

  def determine_state(order)
    # This is not really valid since a shipment with only a package
    # will have a 0 amount
    return 'quote'   if needs_quote? && adjustment.amount == 0
    return 'pending' if self.inventory_units.any? {|unit| unit.backordered?}
    return 'shipped' if state == 'shipped'
    order.payment_state == 'balance_due' ? 'pending' : 'ready'
  end

  def after_ship
    inventory_units.each(&:ship!)
    #TODO Do something with the email
    #ShipmentMailer.shipped_email(self).deliver
  end
end

Order.class_eval do

  scope :quotes, where("shipment_state = 'quote'")

  Order.state_machines[:state] = StateMachine::Machine.new(Order, :initial => 'cart', :use_transactions => false) do
    event :next do
      #transition :cart => :address, :address => :payment, :payment => :confirm, :confirm => :complete
      transition :from => 'cart', :to => 'address'
      transition :from => 'address', :to => 'payment'
      transition :from => 'payment', :to => 'confirm'
      transition :from => 'confirm', :to => 'complete'
    end
    event :cancel do
      transition :to => 'canceled', :if => :allow_cancel?
    end
    event :resume do
      transition :to => 'resumed', :from => 'canceled', :if => :allow_resume?
    end
    event :return do
      transition :to => 'returned', :from => 'awaiting_return'
    end
    event :authorize_return do
      transition :to => 'awaiting_return'
    end
    event :quote do
      transition :from => 'payment', :to => 'quote'
    end
    event :pay do
      transition :from => 'quote', :to => 'payment'
    end
    
    before_transition :to => 'complete' do |order|
      begin
        order.process_payments!
      rescue Spree::GatewayError
        if Spree::Config[:allow_checkout_on_gateway_error]
          true
        else
          false
        end
      end
    end
    
    before_transition :from => 'address', :do => :create_or_update_shipments!
    after_transition :from => 'address', :to => 'payment' do |order|
      order.create_tax_charge!
      order.quote if order.needs_quote?
    end
    after_transition :to => 'complete', :do => :finalize!
    after_transition :to => 'canceled', :do => :after_cancel
  end
  
  UNITED_STATES = Country.find_by_name("United States")

  def quick_quote(address)
    return false if suppliers.any? {|supplier| weight_of_line_items_for_supplier(supplier) > 150}
    if address.country == UNITED_STATES
      ShippingMethod.find(7).calculator.quick_quote(self, address)
    else
      ShippingMethod.find(8).calculator.quick_quote(self, address)
    end
  end
  
  def customer_adjustments
    adjustments.inject({}) do |i,adjustment|
      if i.has_key? adjustment.label
        i[adjustment.label] += adjustment.amount
      else
        i[adjustment.label] = adjustment.amount
      end
      i
    end
  end

  def finalize!
    update_attribute(:completed_at, Time.now)
    self.out_of_stock_items = InventoryUnit.assign_opening_inventory(self)
    adjustments.optional.each {|adjustment| adjustment.update_attribute(:locked, true)}
    set_order_number
    OrderMailer.confirm_email(self).deliver
  end

  def set_order_number
    num = Spree::Config['current_order_id']
    Spree::Config.set('current_order_id' => num.to_i + 1)
    self.update_attribute :number, "R#{num}"
  end

  def needs_quote?
    shipments.any? {|shipment| shipment.state == 'quote'}
  end

  def checkout_allowed?
    line_items.count > 0 && state != "quote"
  end

  def create_shipment!
    create_or_update_shipments!
  end

  def create_or_update_shipments!
    if shipments.any?
      # We should only land here if a customer went to the payment step of the checkout, then
      # went back to the store, possibly added or removed items, and now has submitted the address
      # form again. Since the order had a ship_address, add_variant would have taken care of creating
      # the shipment, or if they removed all items from a shipment, it would be removed.
      # TODO Verify this is also the case in the admin order creator
      update!
    else
      # If a package is in the order then the suppliers will get pulled out, and shipments created
      # but no line items will get added to those shipments since the packages don't generally have
      # a single supplier. The package itself is only related to the order.
      suppliers.each do |supplier|
        shipment = create_shipment(supplier)
        shipments << shipment
        line_items_for_supplier(supplier).each {|line_item| shipment.line_items << line_item}
      end
    end
  end
  
  def add_variant(variant, quantity=1)
    current_item = contains?(variant)
    if current_item
      current_item.quantity += quantity
      current_item.save
    else
      current_item = LineItem.new :quantity => quantity
      current_item.variant = variant
      current_item.price = variant.price
      current_item.supplier = variant.supplier unless variant.is_a_package?
      self.line_items << current_item

      # If a shipping address is on the order then the customer has already
      # been to the checkout, and shipments have been created. Since this
      # item doesn't exist in any shipment, find the shipment the product
      # belongs in, creating it if necessary, and add the item to the shipment
      if ship_address && !variant.is_a_package?
        shipment = find_or_create_shipment_by_supplier current_item.supplier
        self.shipments << shipment unless shipments.include? shipment
        shipment.line_items << current_item
      end
    end

    Variant.additional_fields.select {|f| !f[:populate].nil? && f[:populate].include?(:line_item) }.each do |field|
      value = ""
      field_name field[:name].gsub(' ','_').downcase
      if field[:only].nil? || field[:only].include?(:variant)
        value = variant.send(field_name)
      elsif field[:only].include?(:product)
        value = variant.product.send(field_name)
      end
      current_item.update_attribute field_name, value
    end
    current_item
  end
  
  def update_shipment_state
    old_state = self.shipment_state
    self.shipment_state = case shipments.count
    when 0; then nil
    when shipments.shipped.count; then 'shipped'
    when shipments.ready.count;   then 'ready'
    when shipments.pending.count; then 'pending'
    else 'partial'
    end

    self.shipment_state = 'quote' if needs_quote?
    self.shipment_state = 'backordered' if backordered?
    if old_state == 'quote' && self.shipment_state == 'pending'
      self.pay!
      OrderMailer.quote_email(self).deliver
    end
  end

  def find_or_create_shipment_by_supplier(supplier)
    shipment = shipments.detect {|shipment| shipment.supplier == supplier}
    shipment || create_shipment(supplier)
  end

  def create_shipment(supplier)
    shipping_method = ShippingMethod.all_available(self, :front_end, :supplier => supplier).first
    Shipment.create(
      :order => self,
      :supplier => supplier,
      :shipping_method => shipping_method,
      :address => self.ship_address
    )
  end

  def has_packages?
    line_items.any? {|li| !li.variant.package.nil?}
  end
  
  def weight_of_line_items_for_supplier(supplier)
    Rails.logger.debug(line_items_for_supplier(supplier).inspect)
    line_items_for_supplier(supplier).map {|line_item| line_item.variant.weight * line_item.quantity}.sum
  end
  
  def inventory_units_for_shipment(shipment)
    inventory_units.select {|iu| iu.supplier == shipment.supplier}
  end

  def line_items_for_supplier(supplier)
    line_items.reject {|li| li.supplier.nil?}.select {|li| supplier == li.supplier}
  end

  def suppliers
    return line_items.map(&:supplier).uniq unless has_packages?
    line_items.map(&:variant).map do |variant|
      supplier = variant.package.variants.map(&:supplier) if variant.is_a_package?
      supplier ||= variant.supplier
      supplier
    end.flatten.uniq
  end
end

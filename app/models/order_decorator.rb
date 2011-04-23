Order.class_eval do

  scope :quotes, where("shipment_state = 'quote'")

  Order.state_machines[:state] = StateMachine::Machine.new(Order, :initial => 'cart', :use_transactions => false) do
    event :next do
      #transition :cart => :address, :address => :payment, :payment => :confirm, :confirm => :complete
      transition :from => 'cart', :to => 'address'
      transition :from => 'address', :to => 'quote', :if => :needs_quote?
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
      transition :to => 'quote'
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
    after_transition :to => 'payment', :do => :create_tax_charge!
    after_transition :to => 'complete', :do => :finalize!
    after_transition :to => 'canceled', :do => :after_cancel
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

  def needs_quote?
    shipments.any? {|shipment| shipment.state == 'quote'}
  end

  def create_or_update_shipments!
    if shipments.any?
      update!
    else
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
      current_item.supplier = variant.product.supplier
      self.line_items << current_item

      # If a shipping address is on the order then the customer has already
      # been to the checkout, and shipments have been created. Since this
      # item doesn't exist in any shipment, find the shipment the product
      # belongs in, creating it if necessary, and add the item to the shipment
      if ship_address
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
    self.shipment_state = case shipments.count
    when 0; then nil
    when shipments.shipped.count; then 'shipped'
    when shipments.ready.count;   then 'ready'
    when shipments.pending.count; then 'pending'
    else 'partial'
    end

    self.shipment_state = 'quote' if needs_quote?
    self.shipment_state = 'backordered' if backordered?
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
  
  def weight_of_line_items_for_supplier(supplier)
    line_items_for_supplier(supplier).map {|line_item| line_item.variant.weight * line_item.quantity}.sum
  end

  def line_items_for_supplier(supplier)
    line_items.select {|line_item| supplier == line_item.supplier}
  end

  def suppliers
    @suppliers ||= line_items.map(&:supplier).uniq
  end
end

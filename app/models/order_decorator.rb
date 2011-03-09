Order.class_eval do
  Order.state_machines[:state] = StateMachine::Machine.new(Order, :initial => 'cart', :use_transactions => false) do
  #state_machine :initial => 'cart', :use_transactions => false do
    event :next do
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

    after_transition :to => 'payment', :do => :create_tax_charge_and_shipping!
    after_transition :to => 'complete', :do => :finalize!
    after_transition :to => 'canceled', :do => :after_cancel
  end

  def create_tax_charge_and_shipping!
    create_tax_charge!
    if shipments.any?
      # ???
    else
      suppliers.each {|supplier| self.shipments << create_shipment(supplier)}
    end
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

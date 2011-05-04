Calculator::ActiveShipping.class_eval do
  def compute(shipment)
    return if shipment.nil?
    supplier = shipment.supplier
    addr = shipment.address

    destination = ActiveMerchant::Shipping::Location.new(
      :country => addr.country.iso,
      :state => (addr.state ? addr.state.abbr : addr.state_name),
      :city => addr.city,
      :zip => addr.zipcode
    )
    origin = ActiveMerchant::Shipping::Location.new(
      :country => supplier.country,
      :state => supplier.state,
      :city => supplier.city,
      :zip => supplier.zip
    )
    
    if has_rateable_items(shipment)
      rates = retrieve_rates(origin, destination, packages(shipment))
    else
      return 0
    end
    return nil if rates.empty? or not rates[self.class.description].present?
    (rates[self.class.description].to_f + (supplier.handling_fee.to_f || 0.0)) / 100.0
  end

  def available?(order, options)
    order.weight_of_line_items_for_supplier(options[:supplier]) <= 150
  end

  private

  def has_rateable_items(shipment)
    shipment.order.weight_of_line_items_for_supplier(shipment.supplier) > 0
  end

  def retrieve_rates(origin, destination, packages)
    #TODO Add rescue block back in
    response = carrier.find_rates(origin, destination, packages)
    rate_hash = Hash[*response.rates.map {|rate| [rate.service_name, rate.price] }.flatten]
    return rate_hash
  end

  def packages(shipment)
    multiplier = Spree::ActiveShipping::Config[:unit_multiplier]
    weight = multiplier * shipment.order.weight_of_line_items_for_supplier(shipment.supplier)
    package = ActiveMerchant::Shipping::Package.new(weight, [], :units => Spree::ActiveShipping::Config[:units].to_sym)
    [package]
  end
end

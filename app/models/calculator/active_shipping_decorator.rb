Calculator::ActiveShipping.class_eval do
  def compute(shipment, options={})
    return if shipment.nil?
    supplier = shipment.supplier
    addr = shipment.address || options[:address]

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

  def location(address)
    ActiveMerchant::Shipping::Location.new(address)
  end

  def multiplier
    Spree::ActiveShipping::Config[:unit_multiplier]
  end

  def units
    Spree::ActiveShipping::Config[:units].to_sym
  end

  def quick_quote(order, address)
    Rails.logger.debug(order.suppliers.inspect)
    order.suppliers.map do |supplier|
      weight = order.weight_of_line_items_for_supplier(supplier) * multiplier
      next unless weight > 0
      packages = [package(weight)]
      destination = location({
        :country => supplier.country,
        :state => supplier.state,
        :city => supplier.city,
        :zip => supplier.zip
      })
      origin = location({
        :country => address.country.iso,
        :state => (address.state ? address.state.abbr : address.state_name),
        :city => nil,
        :zip => address.zipcode
      })
      rate = retrieve_rates(origin, destination, packages)[self.description].to_f / 100.0
      Rails.logger.debug(rate)
      rate
    end.sum
  end

  private

  def has_rateable_items(shipment)
    # TODO Make this more intelligent, like a field on the product that states it has
    # free shipping, instead of using weight = 0 for this purpose
    shipment.order.weight_of_line_items_for_supplier(shipment.supplier) > 0
  end

  def retrieve_rates(origin, destination, packages)
    #TODO Add rescue block back in
    response = carrier.find_rates(origin, destination, packages)
    rate_hash = Hash[*response.rates.map {|rate| [rate.service_name, rate.price] }.flatten]
    return rate_hash
  end

  def package(weight)
    ActiveMerchant::Shipping::Package.new(weight, [], :units => units)
  end

  def packages(shipment)
    weight = multiplier * shipment.order.weight_of_line_items_for_supplier(shipment.supplier)
    [package(weight)]
  end
end

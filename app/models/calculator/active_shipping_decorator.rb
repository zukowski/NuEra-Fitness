Calculator::ActiveShipping.class_eval do
  def compute(shipment, options={})
    return if shipment.nil?
    supplier = shipment.supplier
    addr = shipment.address

    #destination = location(shipment.address)
    #destination = location(supplier.address)
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

    return 0 unless has_rateable_items(shipment)
    rates = Rails.cache.fetch(cache_key(origin, destination, shipment.line_items, shipment.order.id)) do 
      rates = retrieve_rates(origin, destination, packages(shipment))
    end
    return nil if rates.empty? or not rates[self.class.description].present?
    (rates[self.class.description].to_f + (supplier.handling_fee.to_f || 0.0)) / 100.0
  end

  def available?(order, options)
    order.weight_of_line_items_for_supplier(options[:supplier]) <= 150
  end

  def quick_quote(order, address)
    Rails.logger.debug("# of Suppliers: #{order.suppliers.count}")
    order.suppliers.inject(0) do |sum,supplier|
      weight = order.weight_of_line_items_for_supplier(supplier) * multiplier
      line_items = order.line_items_for_supplier(supplier)
      next sum if weight == 0
      
      packages = [package(weight)]
      #destination = location(address)
      #destination = location(supplier.address)
      origin = location({
        :country => supplier.country,
        :state => supplier.state,
        :city => supplier.city,
        :zip => supplier.zip
      })
      destination = location({
        :country => address.country.iso,
        :state => (address.state ? address.state.abbr : address.state_name),
        :city => address.city,
        :zip => address.zipcode
      })

      rates = Rails.cache.fetch(cache_key(origin, destination, line_items, order.id)) do
        rates = retrieve_rates(origin, destination, packages)
      end

      next sum if rates.empty? or rates[self.class.description].nil?
      sum + rates[self.description].to_f / 100.0
    end
  end

  private

  def has_rateable_items(shipment)
    # TODO Make this more intelligent, like a field on the product that states it has
    # free shipping, instead of using weight = 0 for this purpose
    shipment.order.weight_of_line_items_for_supplier(shipment.supplier) > 0
  end

  def retrieve_rates(origin, destination, packages)
    begin
      response = carrier.find_rates(origin, destination, packages)
      return Hash[*response.rates.map {|rate| [rate.service_name, rate.price] }.flatten]
    rescue ActiveMerchant::ActiveMerchantError => e
      if [ActiveMerchant::ResponseError, ActiveMerchant::Shipping::ResponseError].include? e.class
        params = e.response.params
        if params["Response"] && params["Response"]["Error"] && params["Response"]["Error"]["ErrorDescription"]
          message = params["Response"]["Error"]["ErrorDescription"]
        else
          message = e.message
        end
      else
        message = e.to_s
      end
      Rails.cache.write @cache_key, {}
      raise Spree::ShippingError.new("#{I18n.t(:shipping_error)}: #{message})")
    end
  end

  # We can't cache the keys in an instance var as there may be multiple shipments
  # each with unique keys
  def cache_key(origin, destination, line_items, id)
    origin_key = "#{origin.country}-#{origin.state}-#{origin.zip}"
    dest_key   = "#{destination.country}-#{destination.state}-#{destination.city}-#{destination.zip}"
    items_key  = "#{line_items.map {|li| li.variant_id.to_s + "_" + li.quantity.to_s}.join('|')}"
    "#{carrier.name}-#{id}-#{origin_key}-#{dest_key}-#{items_key}".gsub(" ","")
  end

  def package(weight)
    ActiveMerchant::Shipping::Package.new(weight, [], :units => units)
  end

  def packages(shipment)
    weight = multiplier * shipment.order.weight_of_line_items_for_supplier(shipment.supplier)
    [package(weight)]
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

end

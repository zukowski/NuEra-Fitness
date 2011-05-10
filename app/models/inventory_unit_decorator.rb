InventoryUnit.class_eval do
  delegate :supplier, :to => :variant
  
  def self.increase(order, variant, quantity)
    package = variant.product.package
    if package
      # Have the package call increase recursively for a packages variants
      # and return as there's no IU for a package itself
      package_variants = package.variants.group(:id)
      variant_count = package_variants.count
      package_variants.each do |package_variant|
        increase(order, package_variant, quantity * variant_count[package_variant.id])
      end
      return
    end

    back_order = determine_backorder(order, variant, quantity)
    sold = quantity - back_order

    if Spree::Config[:track_inventory_levels]
      variant.decrement!(:count_on_hand, quantity)
    end

    if Spree::Config[:create_inventory_units]
      create_units(order, variant, sold, back_order)
    end
  end

  def self.create_units(order, variant, sold, back_order)
    if back_order > 0 && !Spree::Config[:allow_backorders]
      raise "Cannot request back orders when backordering is disabled"
    end
    
    supplier = variant.product.supplier
    shipment = order.shipments.detect {|shipment| !shipment.shipped? && shipment.supplier == supplier}

    sold.times { order.inventory_units.create(:variant => variant, :state => 'sold', :shipment => shipment) }
    back_order.times { order.inventory_units.create(:variant => variant, :state => 'backordered', :shipment => shipment) }
  end
end

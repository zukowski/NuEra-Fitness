ShippingMethod.class_eval do
  def self.all_available(order, display_on=nil, options={})
    all.select {|method| method.available_to_order?(order, display_on, options)}
  end

  def available_to_order?(order, display_on=nil, options={})
    available?(order, display_on, options) && zone && zone.include?(order.ship_address)
  end

  def available?(order, display_on=nil, options={})
    begin
    (self.display_on == display_on.to_s || self.display_on.blank?) && calculator.available?(order, options)
    rescue
      (self.display_on == display_on.to_s || self.display_on.blank?) && calculator.available?(order)
    end
  end
end

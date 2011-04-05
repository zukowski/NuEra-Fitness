class Calculator::Freight < Calculator
  def self.description
    "Freight"
  end

  def self.register
    super
    ShippingMethod.register_calculator(self)
  end

  def compute(order)
    return 0
  end

  def available?(order,options)
    order.weight_of_line_items_for_supplier(options[:supplier]) > 150
  end
end

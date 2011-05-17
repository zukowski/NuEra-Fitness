LineItem.class_eval do
  attr_accessible :quantity, :actual_price
  belongs_to :supplier
  belongs_to :shipment
end

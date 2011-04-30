class Package < ActiveRecord::Base
  has_and_belongs_to_many :variants
  belongs_to :product
  delegate :name, :to => :product
  delegate :price, :to => :product

  def cost
    @cost ||= variants.inject(0) {|p,v| p + v.cost_price}
  end

  def retail
    @retail ||= variants.inject(0) {|p,v| p + v.price}
  end

  def savings
    retail - price
  end

  def profit
    price - cost
  end
end

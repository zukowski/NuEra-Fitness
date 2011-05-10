Product.class_eval do
  belongs_to :supplier
  has_one :package
end

Product.class_eval do
  belongs_to :supplier
  has_one :package
  has_and_belongs_to_many :videos
end

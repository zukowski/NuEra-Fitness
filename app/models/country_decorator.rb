Country.class_eval do
  def self.all
    Country.where("iso3 = 'USA' OR iso3 = 'CAN'").order('name DESC') 
  end
end

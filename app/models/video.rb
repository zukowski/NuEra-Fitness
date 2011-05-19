class Video < ActiveRecord::Base
	has_and_belongs_to_many :products
	
	validates_presence_of :name, :description, :url, :publish_up
	
	#def active?
		#self.publish_up > Date.today
	#end
end

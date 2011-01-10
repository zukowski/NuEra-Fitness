##
# These rake tasks take XML dumps for BigCommerce and import users
# and orders into Spree.
#
# Here's how we map fields from BIgC to Spree
#
# Users
#
#	BigC			Spree
#	----------		-----------
#	Customer_ID		id
#	First_Name		-
#	Last_Name		-
#	Company			-
#	Email			email
#	Phone			-
#	Notes			-
#	Store_Credit		-
#	Customer_Group		-
#	Date_Joined		created_at
#
#
# Addresses
#
#	In BigC, addresses are associated with users.
#	In Spree, addresses are associated with orders, not users.
#
#	BigC			Spree
#	----------		----------
#	Address_First_Name	firstname
#	Address_Last_Name	lastname
#	Address_Company		-
#	Address_Line_1		address1
#	Address_Line_2		address2
#	CitySuburb		city
#	StateProvince		state_name
#	State_Abbreviation	state_id
#	ZipPostcode		zipcode
#	Country			country_id
#	Address_Phone		phone
##

namespace :migrate do
  
  desc "Migrate users from BigCommerce into Spree"
  task :users => :environment do
    doc = load_xml 'bigc/customers-2011-01-09.xml'  
    
    doc.xpath('//customers//customer').each do |customer|
      bigc_id    = customer./('.//Customer_ID').first.content
      email      = customer./('.//Email').first.content
      created_at = customer./('.//Date_Joined').first.content
      created_at = "#{created_at.slice(6,4)}-#{created_at.slice(0,2)}-#{created_at.slice(3,2)}"
      
      # create a new user object
      user = User.new :email => email, :login => email
      
      # assign db-only properties
      user.created_at = created_at
      user.bigc_id = bigc_id

      # create a default password for all users
      # TODO change this to a unique random pw when we send out 
      # pw reset emails
      user.password = "abc123"
      
      # insert the user record
      user.save
    end
  end
  
  desc "Migrate addresses from BigCommerce into Spree"
  task :addresses => :environment do
    doc = load_xml 'bigc/customers-2011-01-09.xml'

    doc.xpath('//customers//customer//Addresses//item').each do |add|
      address1   = add./('.//Address_Line_1').first.content
      address2   = add./('.//Address_Line_2').first.content
      city       = add./('.//CitySuburb').first.content
      state_name = add./('.//StateProvince').first.content
      zipcode    = add./('.//ZipPostcode').first.content
      phone      = add./('.//Address_Phone').first.content 

      # fetch state_id from spree
      # TODO What do we do with abbreviation like QC for Quebec which are
      # not in the Spree states table? Setting state_id to nil for now if so.
      abbr = add./('.//State_Abbreviation').first.content
      state = State.first(:conditions => ["abbr = '#{abbr}'"])
      state_id = state.nil? ? nil : state.id

      # fetch country_id from Spree
      country = add./('.//Country').first.content
      country_id = Country.first(:conditions => ["name = '#{country}'"]).id
      puts country_id
    end
  end

  # loads an xml file using nokogiri
  def load_xml file
    f = File.open file
    doc = Nokogiri::XML f
    f.close
    doc
  end
end

require 'nokogiri'

customers_file = 'customers-2011-01-09.xml'  
f = File.open customers_file
doc = Nokogiri::XML f
f.close

# This section does the actual parsing and data entry

##
# Here's how we map fields from BIgC to Spree
#
# Users
#
# 	In the BigC customer XML export, each <customer> has as <Addresses>
#	node,  so we'll handle the address inserts immediately after the
#	user insert for each record.
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
#	BigC			Spree
#	----------		----------
#	Address_First_Name	firstname
#	Address_Last_Name	lastname
#	Address_Company		-
#	Address_Line_1		address1
#	Address_Line_2		address2
#	CitySuburb		city
#	StateProvince		state_id
#	State_Abbreviation	-
#	ZipPostcode		zipcode
#	Country			country_id
#	Address_Phone		phone
##

# with each customer
doc.xpath('//customers//customer').each do |customer|
  email = customer./('.//Email').first.content
  created_at = customer./('.//Date_Joined').first.content
  addresses = []
  
  customer./('.//Addresses').each do |address|
  
  end
  
  user User.new :email => email, :created_at => created_at
  puts user
 
end
# 	insert user
# 	with each Addresses
#		fetch state_id for StateProvince
#		fetch country_id for Country
#		insert address

	

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
#	Address_Line_2	        address2
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
    
    count = 0
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
      count += 1
    end

    puts "Created #{count} users."
  end
  
  desc "Migrate addresses from BigCommerce into Spree"
  task :addresses => :environment do
    doc = load_xml 'bigc/customers-2011-01-09.xml'

    count_addresses = 0
    count_states = 0
    doc.xpath('//customers/customer').each do |customer|
     customer./('.//Addresses//item').each do |add|
        firstname  = add./('.//Address_First_Name').first.content
        lastname   = add./('.//Address_Last_Name').first.content
        address1   = add./('.//Address_Line_1').first.content
        address2   = add./('.//Address_Line_2').first.content
        city       = add./('.//CitySuburb').first.content
        state_name = add./('.//StateProvince').first.content
        zipcode    = add./('.//ZipPostcode').first.content
        phone      = add./('.//Address_Phone').first.content 
      
        # fetch country_id from Spree db
        country = add./('.//Country').first.content
        country_id = Country.where("name = ?",country).id

        # fetch state_id from Spree db
        # TODO What do we do with abbreviation like QC for Quebec which are
        # not in the Spree states table? Setting state_id to nil for now if so.
        abbr = add./('.//State_Abbreviation').first.content
        state = State.where("abbr = ?",abbr)
        # if no state found, create it
        # (we need to do this because Spree doesn't come loaded with Canadian provinces)
        if state.nil?
          new_state = State.new :name       => state_name,
                                :abbr       => abbr,
                                :country_id => country_id
          state_id = new_state.id
          state_name = new_state.name
          new_state.save
          count_states += 1
        else
          state_id = state.id
          state_name = state.name
        end
      
        # create address
        address = Address.new :firstname  => firstname,
                              :lastname   => lastname,
                              :address1   => address1,
                              :address2   => address2,
                              :city       => city,
                              :state_id   => state_id,
                              :zipcode    => zipcode,
                              :country_id => country_id, 
                              :state_name => state_name,
                              :phone      => phone
        address.save
        count_addresses += 1
      end
    end

    puts "Created #{count_addresses} addresses and #{count_states} states."
  end

  desc "Migrate Shipping Methods from BigCommerce to Spree"
  task :shipping_methods => :environment do
    doc = load_xml 'bigc/orders-2011-01-09.xml'
    shipping_methods = []
    
    ShippingMethod.all.each do |method|
      method.destroy
    end
    
    doc.xpath('//orders//order').each do |order|
      method = order./('.//Ship_Method').first.content
      if (!method.nil? && method != "" && !shipping_methods.include?(method))
        shipping_methods.push method
        spree_ship_method = ShippingMethod.new :name => method
        spree_ship_method.zone_id = 2 # North America
        spree_ship_method.display_on = 'back_end';
        spree_ship_method.save
        
        # create calculator associated with shipping method
        
      end
    end
  end

  desc "Migrate orders from BigCommerce into Spree"
  task :orders => :environment do
    doc = load_xml 'bigc/orders-2011-01-09.xml'
    
    # first let's run some tests and see if we can match all of the
    # BigC line items to product variants in Spree
    variants_found = []
    variants_not_found = []
    bigc_items_no_sku = []
  
    doc.xpath('//orders//order').each do |order|
      order./('.//item').each do |item|
        sku = item./('.//Product_SKU').first.content
        id = item./('.//Product_ID').first.content
        product_name = item./('.//Product_Name').first.content
        variant = Variant.where("sku = ?",sku)
        product = Product.where("name = ?",product_name)
        if variant.nil? && product.nil? && !variants_not_found.include?(product_name)
          variants_not_found.push product_name
        end
        if ((!variant.nil? || product.nil?) && !variants_found.include?(product_name))
	  variants_found.push product_name
        end
        if sku == "" && !bigc_items_no_sku.include?(product_name)
          bigc_items_no_sku.push product_name
        end
      end  
    end

    puts variants_found.length.to_s + " variants found."
    puts variants_not_found.length.to_s + " variants not found."
    puts bigc_items_no_sku.length.to_s + " BigC order items with blank or missing SKU."
    # end tests
    
    # destroy all existing orders
    Order.all.each do |order|
      #order.destroy
    end

    # create the orders
    doc = load_xml 'bigc/orders-2011-01-09.xml'
    doc.xpath('//orders//order').each do |order|
      puts "Creating new order..."
      spree_order = Order.new
      email = order./('.//Customer_Email').first.content
      bigc_id = order./('.//Customer_ID').first.content
      billing_email = order./('.//Billing_Email').first.content
      status = order./('.//Order_Status').first.content
      if status == 'Cancelled'
        puts 'Cancelled'
        next
      end
      user = User.where('bigc_id = ? OR email = ?',bigc_id,email).first
      if user.nil?
        #puts "\t****WARNING: No user with bigc_id = #{bigc_id} OR email = '#{email}'"
        #puts "\tCreating new user..."
        user = User.new
        user.email = billing_email
        user.login = billing_email
        user.password = 'abc123'
        user.save
        #puts "\tCreated new user for #{billing_email}"
      else        
        #puts "    Found user match for #{email} based on BigC Customer_ID"
      end
      
      spree_order.user_id = user.id
      spree_order.email = user.email
      spree_order.state = 'complete';
     
      shipping_method = ShippingMethod.where('name = ?','Legacy').first
      if shipping_method.nil?
        #puts "****ERROR: You must have a shipping method called 'Legacy' before importing orders from BigC"
      end
 
      spree_order.shipping_method_id = shipping_method.id
      spree_order.shipment_state = 'shipped'
      spree_order.save

      # add line items to order
      #puts "\tCreating line items..."
      order./('.//item').each do |item|
        #puts "\t\tCreating line item..."
        item_name = item./('.//Product_Name').first.content
        # provide some corrections to product names
        if item_name == 'The Prospect - Modified'
          item_name = 'The Prospect'
        end
        item_sku = item./('.//Product_SKU').first.content
	#puts "\t\t\tBigC line item found: #{item_name}"
        #puts "\t\t\tSearching for Spree product..."
        product = Product.where("name = ?",item_name).first
        if product.nil?
	  #puts "\t\t****WARNING: No Spree product found by that name, trying with variant SKU..."
          product = Product.where("id = (SELECT product_id FROM variants where sku = ?)",item_sku).first
        end
        if product.nil?
          #puts "****ERROR: No Spree product found by searching on variant SKU = '#{item_sku}'"
        else
          #puts "\t\t\tSpree product found"
          #puts "\t\t\tSearching for Spree variant for this product..."
          variant = Variant.where("id = ?",product.id).first
          if variant.nil?
	    #puts "****ERROR: No Spree variant found"
          else       
            #puts "\t\t\tSpree variant found"
            line_item = LineItem.new
	    line_item.variant_id = variant.id
            line_item.order_id = spree_order.id
            line_item.quantity = item./('.//Product_Qty').first.content
            line_item.save
            #puts "\t\tLine item created"
          end
        end
      end
      #puts "\tCreate line item"

      # create adjustment for shipping cost
      #adjustment = Adjustment.new
      #adjustment.order_id = spree_order.id
      #adjustment.label = 'shipping';
      #adjustment.amount = order./('.//Shipping_Cost').first.content
      #adjustment.save

      # create shipment
      #puts "\tCreating shipment..."
      #ship_date = order./('.//Date_Shipped').first.content       
      #shipment = spree_order.shipment #Shipment.new :cost => order./('.//Shipping_Cost').first.content
      #if shipment.nil?
      #  spree_order.create_shipment!
      #  shipment = spree_order.shipment
      #end
      #shipment.order_id = spree_order.id
      #shipment.shipped_at = "#{ship_date.slice(6,4)}-#{ship_date.slice(0,2)}-#{ship_date.slice(3,2)}"
      #shipment.shipping_method_id = shipping_method.id
      #shipment.tracking = order./('.//Tracking_No').first.content
      #shipment.state = "shipped";
      #shipment.save
      #puts "\tShipment created"
      #spree_order.update!
      #spree_order.save

      # create adjustment for shipping cost
      #adjustment = Adjustment.new
      #adjustment.order_id = spree_order.id
      #adjustment.label = 'shipping';
      #adjustment.amount = order./('.//Shipping_Cost').first.content
      #puts adjustment.inspect
      #adjustment.save
      #puts adjustment.errors

      # create payment
      #puts "\tCreating payment..."
      #bigc_payment_method = order./('.//Payment_Method').first.content
      #payment_method = PaymentMethod.where('name = ?',bigc_payment_method).first
      #payment = Payment.new
      #if payment_method.nil?
      #  puts "\t****WARNING: BigC says payment method is '#{bigc_payment_method}', but no such method found in Spree"
      #  payment_method = PaymentMethod.where('name = ?','Not Specified').first
      #  puts "\t\tUsing 'Not Specified' method instead"
      #  payment.payment_method_id = payment_method.id
      #else
      # payment.payment_method_id = payment_method.id
      #end
      #payment.order_id = spree_order.id
      #payment.amount = order./('.//Order_Total').first.content
      #payment.state = "completed"
      #payment.save
      #puts "\tPayment created"

      # set some other order properties
      order_date = order./('.//Order_Date').first.content
      spree_order.completed_at = spree_order.created_at = "#{order_date.slice(6,4)}-#{order_date.slice(0,2)}-#{order_date.slice(3,2)}"       
      #spree_order.adjustment_total = spree_order.shipment.cost
      spree_order.payment_total = order./('.//Order_Total').first.content
      spree_order.total = order./('.//Order_Total').first.content
      spree_order.payment_state = 'paid'
      #spree_order.update!
      spree_order.save
      #ad = Adjustment.where('order_id = ?',spree_order.id).first
      #Adjustment.update(ad.id,:amount => order./('.//Shipping_Cost').first.content)      
      #puts "Order created\n\n"
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

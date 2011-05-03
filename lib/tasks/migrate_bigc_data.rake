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
  
  desc "Test order totals"
  task :test_order_totals => :environment do
    doc = load_xml 'bigc/orders.xml'
    count = 0
    wrong = 0
    doc.xpath('//orders/order').each do |order|
      count = count + 1
      id = order./('.//Order_ID').first.content
      subtotal = order./('.//Subtotal').first.content.to_f
      shipping = order./('.//Shipping_Cost').first.content.to_f
      total    = order./('.//Order_Total').first.content.to_f
      subship  = (subtotal + shipping).round(2)
      if (subship) != total
        wrong = wrong + 1
        puts "#{subtotal} + #{shipping} != #{total} [#{subship}] #{id}" 
      end
    end
    puts "#{count} orders / #{wrong}"
  end

  desc "Migrate users from BigCommerce into Spree"
  task :users => :environment do
    doc = load_xml 'bigc/customers.xml'  
    
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
      user.password = "aw3d#4$"
      user.password_confirmation = "aw3d#4$"

      # insert the user record
      user.save
      count += 1
    end

    puts "Created #{count} users."
  end
  
  desc "Migrate addresses from BigCommerce into Spree"
  task :addresses => :environment do
    doc = load_xml 'bigc/customers.xml'

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

  desc "Migrate orders from BigCommerce into Spree"
  task :orders => :environment do
    doc = load_xml 'bigc/orders.xml'
    
    # first let's run some tests and see if we can match all of the
    # BigC line items to product variants in Spree
  
    doc.xpath('//orders//order').each do |order|
      id = order./('.//Order_ID').first.content
      order./('.//item').each do |item|
        sku = item./('.//Product_SKU').first.content
        product_name = item./('.//Product_Name').first.content

        product = find_sku(sku,product_name)

        if product.nil?
          puts "Could not find SKU(#{sku}) or Name(#{product_name}) on order ##{id}"
        end
      end  
    end

    # end tests
    
    # destroy all existing orders
    #Order.all.each do |order|
    #  order.destroy
    #end

    # create the orders
    doc = load_xml 'bigc/orders.xml'
    doc.xpath('//orders//order').each do |order|
      order_id = order./('.//Order_ID').first.content
      email = order./('.//Customer_Email').first.content
      bigc_id = order./('.//Customer_ID').first.content
      billing_email = order./('.//Billing_Email').first.content
      status = order./('.//Order_Status').first.content

      unless status == 'Shipped' || status == 'Completed'
        puts "Skipping #{order_id}, not shipped or completed (#{status})"
        next
      end

      user = User.find_by_bigc_id(bigc_id)
      user ||= User.find_by_email(email)

      if user.nil?
        puts "Skipping #{order_id}, customer not found"
        next
      end

      spree_order = Order.new
      spree_order.user_id = user.id
      spree_order.email = user.email
      spree_order.state = 'complete';
      shipping_method = ShippingMethod.where('name = ?','Legacy').first
      spree_order.shipping_method_id = shipping_method.id
      spree_order.shipment_state = 'shipped'
      spree_order.save

      bill_country = Country.find_by_name(order./('.//Billing_Country').first.content
      ship_country = Country.find_by_name(order./('.//Shipping_Country').first.content
      bill_state   = State.find_by_abbr(order./('.//Billing_State_Abbreviation').first.content
      ship_state   = State.find_by_abbr(order./('.//Shipping_state_abbreviation').first.content
      
      spree_order.bill_address = Address.create({
        :firstname => order./('.//Billing_First_Name').first.content,
        :lastname  => order./('.//Billing_Last_Name').first.content,
        :address1  => order./('.//Billing_Street_1').first.content,
        :address2  => order./('.//Billing_Street_2').first.content,
        :city      => order./('.//Billing_Suburb').first.content,
        :zipcode   => order./('.//Billing_Zip').first.content,
        :phone     => order./('.//Billing_Phone').first.content,
        :company   => order./('.//Billing_Company').first.content,
        :state     => bill_state,
        :country   => bill_country
      })
      spree_order.ship_address = Address.create({
        :firstname => order./('.//Shipping_First_Name').first.content,
        :lastname  => order./('.//Shipping_Last_Name').first.content,
        :address1  => order./('.//Shipping_Street_1').first.content,
        :address2  => order./('.//Shipping_Street_2').first.content,
        :city      => order./('.//Shipping_Suburb').first.content,
        :zipcode   => order./('.//Shipping_Zip').first.content,
        :phone     => order./('.//Shipping_Phone').first.content,
        :company   => order./('.//Shipping_Company').first.content,
        :state     => ship_state,
        :country   => ship_country
      })

      spree_order.save

      # add line items to order
      order./('.//item').each do |item|
        item_name = item./('.//Product_Name').first.content
        item_sku = item./('.//Product_SKU').first.content

        variant = find_variant_by_sku_or_name(item_sku,item_name)
        
        line_item = LineItem.new(:quantity => item./('.//Product_Qty').first.content)
	    line_item.variant = variant
        line_item.price = variant.price
        line_item.supplier = variant.product.supplier
        line_item.save
        spree_order.line_items << line_item

        shipment = spree_order.shipments.detect {|s| s.supplier == line_item.supplier}
        if shipment.nil?
          shipment = Shipment.create({
            :order => spree_order,
            :supplier => supplier,
            :shipping_method => shipping_method,
            :address => spree_order.ship_address
          })
          spree_order.shipments << shipment
          ship_date = order./('.//Date_Shipped').first.content       
          shipment.shipped_at = "#{ship_date.slice(6,4)}-#{ship_date.slice(0,2)}-#{ship_date.slice(3,2)}"
          shipment.tracking = order./('.//Tracking_No').first.content
          shipment.state = shipped
          shipment.save
        end
        shipment.line_items << line_item
      end
      
      order.adjustments << Adjustment.create({
        :label => 'shipping',
        :amount => order./('.//Shipping_Cost').first.content,
        :locked => true
      })

      tax_name = order./('.//Tax_Name')
      
      if tax_name == 'Colorado State Tax'
        order.adjustments << Adjustment.create({
          :label => 'state tax',
          :amount => order./('.//Tax_Total').first.content,
          :locked => true
        })
      end

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

def find_varaitn_by_sku_or_name(item_sku, name)
  if item_sku == "ERFR36"; then item_sku = "NEFR36"; end
  if name =~ /^(?:Crossfit )?Strength Bands Starter Package/
    item_sku = "SBSP"
  elsif name =~ /^Strength Bands Complete Package/
    item_sku = "SBCP"
  elsif name =~ /^Nu Era (?:Fitness )?([0-9]{2})lb Medicine Ball/
    item_sku = "NEFMB#{$1}"
  elsif name =~ /([0-9]{2})lb Nu Era Med Ball/
    item_sku = "NEFMB#{$1}"
  elsif name =~ /^The Prospect/
    item_sku = "LEGACY001"
  elsif name =~ /^Nu Era Champ Customer Pkg/
    item_sku = "LEGACY002"
  elsif name =~ /^The Basics/
    item_sku = "LEGACY003"
  elsif name =~ /^The Elite/
    item_sku = "LEGACY004"
  elsif name =~ /^The Essential/
    item_sku = "LEGACY005"
  elsif name =~ /^Manilla Rope w\/ Poly End & Metal Clamp \(9 ft\)/
    item_sku = "M29M"
  elsif name =~ /^6ft Nylon Rope w\/ Poly End & Metal Clamp 1 1\/2 inch/
    item_sku = "M26M"
  end
  Variant.find_by_sku(item_sku)
end

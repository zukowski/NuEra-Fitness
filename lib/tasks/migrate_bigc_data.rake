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
    shipping_method = ShippingMethod.find_by_name('Legacy')
    payment_method = PaymentMethod.find_by_name('Legacy')

    unless shipping_method && payment_method
      puts "Could not find Legacy shipping and payment method, aborting"
      exit
    end
    
    unless Rails.env.production?
      Order.delete_all
      Shipment.delete_all
      LineItem.delete_all
      InventoryUnit.delete_all
      Adjustment.delete_all
      Payment.delete_all
      Address.delete_all
    end

    # create the orders
    count = 0
    skipped_ids = Array.new
    doc = load_xml 'bigc/orders.xml'
    doc.xpath('//orders//order').each do |order|
      count += 1
      order_id = order./('.//Order_ID').first.content
      email = order./('.//Customer_Email').first.content
      bigc_id = order./('.//Customer_ID').first.content
      billing_email = order./('.//Billing_Email').first.content
      status = order./('.//Order_Status').first.content

      unless status == 'Shipped' || status == 'Completed'
        puts "Skipping #{order_id}, not shipped or completed (#{status})"
        skipped_ids << order_id
        next
      end

      user = User.find_by_bigc_id(bigc_id)
      user ||= User.find_by_email(email)

      if user.nil?
        puts "Skipping #{order_id}, customer not found"
        skipped_ids << order_id
        next
      end

      subtotal = order./('.//Subtotal').first.content.to_f
      taxtotal = order./('.//Tax_Total').first.content.to_f
      shipcost = order./('.//Shipping_Cost').first.content.to_f
      handcost = order./('.//Handling_Cost').first.content.to_f
      discount = order./('.//Discount_Total').first.content.to_f rescue 0
      adjtotal = (taxtotal + shipcost + handcost - discount).round(2)
      total    = order./('.//Order_Total').first.content.to_f

      #puts "BigC Totals"
      #puts "SubTotal: #{subtotal}"
      #puts "Tax: #{taxtotal}"
      #puts "Shipping: #{shipcost}"
      #puts "Handling: #{handcost}"
      #puts "Discount: #{discount}"
      #puts "Total: #{total}"

      calc_total = (subtotal + taxtotal + shipcost + handcost - discount).round(2) 
      diff = (total - calc_total).round(2)

      if diff != 0
        puts "Skipping #{order_id}: #{subtotal} + #{taxtotal} + #{shipcost} + #{handcost} = #{calc_total} != #{total} [#{diff}]"
        skipped_ids << order_id
        next
      end

      spree_order = Order.create
      spree_order.user_id = user.id
      spree_order.email = user.email
      spree_order.state = 'complete';
      spree_order.shipping_method_id = shipping_method.id
      spree_order.shipment_state = 'shipped'
      spree_order.number = order_id
      spree_order.save

      bill_country = Country.find_by_name(order./('.//Billing_Country').first.content)
      ship_country = Country.find_by_name(order./('.//Shipping_Country').first.content)
      bill_state   = State.find_by_abbr(order./('.//Billing_State_Abbreviation').first.content)
      ship_state   = State.find_by_abbr(order./('.//Shipping_State_Abbreviation').first.content)
      
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
      
      ship_date = order./('.//Date_Shipped').first.content
      date = "#{ship_date.slice(6,4)}-#{ship_date.slice(0,2)}-#{ship_date.slice(3,2)}"
      spree_order.shipments.create({
        :supplier => Supplier.first,
        :shipping_method => shipping_method,
        :address => spree_order.ship_address,
        :shipped_at => date,
        :tracking => order./('.//Tracking_No').first.content,
        :state => 'shipped'
      })
      shipment = spree_order.shipments.first
      shipment.update_attributes_without_callbacks({
        :created_at => date,
        :updated_at => date
      })
      # add line items to order
      order./('.//item').each do |item|
        item_name = item./('.//Product_Name').first.content
        item_sku = item./('.//Product_SKU').first.content

        variant = find_variant_by_sku_or_name(item_sku,item_name)
        
        line_item = LineItem.new(:quantity => item./('.//Product_Qty').first.content)
	    line_item.variant = variant
        line_item.price = item./('./Product_Unit_Price').first.content
        line_item.supplier = variant.product.supplier
        spree_order.line_items << line_item
        shipment.line_items << line_item
      end
      spree_order.update_attribute(:item_total, spree_order.line_items.collect {|li| li.price * li.quantity}.sum)

      spree_order.adjustments.shipping.first.update_attributes_without_callbacks({
        :amount => shipcost,
        :locked => true
      })

      if taxtotal > 0
        rate = TaxRate.match(spree_order.bill_address) || TaxRate.match(spree_order.ship_address)
        if rate.nil?
          puts "Error getting TaxRate for #{order_id}"
          next
        end
        rate.create_adjustment(I18n.t(:tax), spree_order, spree_order, true)
      end

      if discount > 0
        spree_order.adjustments.create({
          :label => 'Discount',
          :amount => (0-discount)
        })
      end

      spree_order.payments.create({
        :amount => total,
        :state => 'completed',
        :payment_method => payment_method,
        :source => payment_method
      })
      spree_order.payment_state = 'paid'

      spree_order.adjustments.optional.each {|adjustment| adjustment.update_attribute :locked, true}

      order_date = order./('.//Order_Date').first.content
      date = "#{order_date.slice(6,4)}-#{order_date.slice(0,2)}-#{order_date.slice(3,2)}"
      spree_order.update_attributes_without_callbacks({
        :completed_at => date,
        :created_at => date,
        :shipment_state => 'shipped'
      })
      spree_order.payments.first.update_attributes_without_callbacks({
        :created_at => date
      })
      
      spree_order.update_attribute :payment_total, spree_order.payments.first.amount
      spree_order.update_attribute :adjustment_total, spree_order.adjustments.collect(&:amount).sum
      spree_order.update_attribute :total, spree_order.item_total + spree_order.adjustment_total

      #puts "Spree Totals"
      #puts "SubTotal #{spree_order.item_total}"
      #puts "Tax #{spree_order.adjustments.tax.first.try(:amount)}"
      #puts "Adjustments #{spree_order.adjustment_total}"
      #puts "Total #{spree_order.total}"
      #puts "Payment #{spree_order.payment_total}"
      
      if total != spree_order.total
        puts "Totals do not match #{total} != #{spree_order.total} [#{order_id}]"
      elsif subtotal != spree_order.item_total
        puts "Subtotals do not match"
      elsif adjtotal != spree_order.adjustment_total
        puts "Adjustments do not match"
      elsif total != spree_order.payment_total
        puts "Payment does not match"
      else
        puts "Created [#{count}/247]"
      end
    end
    puts "Skipped #{skipped_ids.count}/#{count} orders"
    puts skipped_ids.inspect
  end
 
  # loads an xml file using nokogiri
  def load_xml file
    f = File.open file
    doc = Nokogiri::XML f
    f.close
    doc
  end
end

def find_variant_by_sku_or_name(item_sku, name)
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

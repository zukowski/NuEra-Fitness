namespace :google_base do
  desc "Create XML and upload to Google Base"
  task :generate => :environment do
    results = '<?xml version="1.0"?>' + "\n" + '<rss version="2.0" xmlns:g="http://base.google.com/ns/1.0">' + _build_xml + '</rss>'
    File.open("#{RAILS_ROOT}/public/google_base.xml", "w") do |io|
      io.puts(results)
    end
  end
end

def _get_product_type(product)
  product_type = ''
  product.taxons.each do |taxon|
    #if taxon.parent_id == 20 
      puts taxon.parent_id
    #end
    #if taxon.priority > priority
    #  priority = taxon.priority
    #  product_type = taxon.name
    #end
  end
  product_type
end

def _build_xml
  returning '' do |output|
    @public_dir = 'http://nuerafitness.com/' #Spree::GoogleBase::Config[:public_domain] || ''
    xml = Builder::XmlMarkup.new(:target => output, :indent => 2, :margin => 1)
    xml.channel {
      xml.title 'Nu Era Fitness Products' #Spree::GoogleBase::Config[:google_base_title] || ''
      xml.link @public_dir
      xml.description 'Products from the Nu Era Fitness online store' #Spree::GoogleBase::Config[:google_base_desc] || ''
      Product.find(:all, :include => [ :images, :taxons ]).each do |product|
        xml.item {
          xml.id product.id.to_s
          xml.mpn product.sku.to_s #remove if the sku is not the same as the manufacturer's part number
          xml.title product.name
          xml.link @public_dir + 'products/' + product.permalink
          xml.description CGI.escapeHTML(product.description)
          xml.price (product.price.to_s + ' ' + 'USD') #Spree::GoogleBase::Config[:google_base_currency_code])
          xml.condition 'new'
          xml.image_link @public_dir.sub(/\/$/, '') + product.images.first.attachment.url(:product) unless product.images.empty?
          xml.product_type _get_product_type(product)
          #TODO: xml.quantity, xml.brand
          
          #See http://base.google.com/support/bin/answer.py?answer=73932&hl=en for all other fields
        }
      end
    }
  end
end

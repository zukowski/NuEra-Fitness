module ApplicationHelper
  def squash_adjustments(adjustments)
    adjustments.inject({}) do |squash,adjustment|
      if squash.has_key? adjustment.label
        squash[adjustment.label] += adjustment.amount
      else
        squash[adjustment.label] = adjustment.amount
      end
      squash
    end
  end

  def link_to_facebook
    link_to 'http://www.facebook.com/pages/Nu-Era-Fitness/107550029321028', :target => '_blank' do
      image_tag '/images/facebook-over.png', :mouseover => '/images/facebook-over.png', :class => 'hover', :border => '0'
    end
  end

  def link_to_twitter
    link_to 'https://twitter.com/#!/NuEraFitness', :target => '_blank' do
      image_tag '/images/twitter-over.png', :mouseover => '/images/twitter-over.png', :class => 'hover', :border => '0', :style => 'margin-top: -1px;'
    end
  end

  # FIXME
  # Potential XSS source if any of the address fields contain html tags
  def customer_details(address)
    "#{address.firstname} #{address.lastname}<br />#{address.address1}<br />#{address.address2 + '<br />' unless address.address2.blank?}#{address.city}, #{address.state.name} #{address.zipcode}<br />#{address.country.name}".html_safe
  end
end

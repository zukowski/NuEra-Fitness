CheckoutHelper.module_eval do
  def checkout_progress
    if @order.state == 'quote'
      states = %w(address quote)
    else
      states = %w(address payment confirm complete)
    end

    items = states.map do |state|
      text = t("order_state.#{state}").titleize
      css_classes = []
      current_index = states.index(@order.state)
      state_index = states.index(state)

      if state_index < current_index
        css_classes << 'completed'
        text = link_to text, checkout_state_path(state)
      end

      css_classes << 'next' if state_index == current_index + 1
      css_classes << 'current' if state == @order.state
      css_classes << 'first' if state_index == 0
      css_classes << 'last' if state_index == states.length - 1
      
      content_tag('li', content_tag('span', text), :class => css_classes.join('-'))
    end
    content_tag('ol', raw(items.join("\n")), :class => 'progress-steps', :id => "checkout-step-#{@order.state}")
  end
end

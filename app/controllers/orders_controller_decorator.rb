OrdersController.class_eval do
  def update
    @order = current_order
    if @order.update_attributes(params[:order])
      @order.line_items = @order.line_items.select {|li| li.quantity > 0}
      # Reload orders to ensure the proper suppliers are returned on the next call to shipment.is_required?
      @order.reload
      @order.shipments = @order.shipments.select {|shipment| shipment.is_required? }
      @order.adjustments = @order.adjustments.select {|adj| !adj.source.nil?}
      redirect_to cart_path
    else
      render :edit
    end
  end

  def edit
    @address = Address.new(session[:address])
    @order = current_order(true)
  end

  def quote
    session[:address] = params[:address] if session[:address].nil?
    @order = current_order
    begin
      @quote = @order.quick_quote(Address.new(params[:address]))
    rescue Spree::ShippingError => e
      @quote = false
      @message = e.message
    end
  end

  def empty
    @order.empty if @order = current_order
    redirect_to cart_path
  end
end

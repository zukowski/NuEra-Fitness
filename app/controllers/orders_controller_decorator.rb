OrdersController.class_eval do
  def update
    @order = current_order
    if @order.update_attributes(params[:order])
      @order.line_items = @order.line_items.select {|li| li.quantity > 0}
      @order.shipments = @order.shipments.select {|ship| ship.line_items.count > 0}
      redirect_to cart_path
    else
      render :edit
    end
  end

  def empty
    if @order = current_order
      @order.shipments.destroy_all
      @order.line_items.destroy_all
    end
    redirect_to cart_path
  end
end

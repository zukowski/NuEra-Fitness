OrdersController.class_eval do
  def empty
    if @order = current_order
      @order.shipments.destroy_all
      @order.line_items.destroy_all
    end
    redirect_to cart_path
  end
end

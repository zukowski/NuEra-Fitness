CheckoutController.class_eval do
  def update
    if @order.update_attributes object_params
      if @order.next
        state_callback :after
      else
        flash[:error] = "Processing Error"
        redirect_to checkout_state_path(@order.state) and return
      end

      if @order.state == "complete" || @order.completed?
        flash[:notice] = I18n.t :order_processed_successfully
        flash[:commerce_tracking] = "nothing special"
        redirect_to completion_route
      elsif @order.state == "quote"
        flash[:notice] = I18n.t :quote_processed_successfully
        redirect_to completion_route
      else
        redirect_to checkout_state_path @order.state
      end
    else
      render :edit
    end
  end
  
  private

  def load_order
    if params[:id] && params[:state] == 'payment'
      @order = Order.find_by_id(params[:id])
      session[:order_id] = @order.id
    end
    @order = current_order unless @order && @order.user == current_user
    redirect_to cart_path and return unless @order and @order.checkout_allowed?
    redirect_to cart_path and return if @order.completed?
    @order.state = params[:state] if params[:state]
    state_callback(:before)
  end
    
  
  def state_callback(before_or_after = :before)
    state = params[:action] == 'update' ? params[:state] : @order.state
    method_name = :"#{before_or_after}_#{params[:action]}_#{state}"
    send(method_name) if respond_to?(method_name, true)
  end

  def before_edit_address
    before_address
  end

  def before_update_address
  end

  def before_update_payment
    current_order.payments.destroy_all
  end

  def after_update_confirm
    session[:order_id] = nil
  end

  def after_update_address
    session[:order_id] = nil if @order.quote?
  end
end

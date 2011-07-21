Admin::OrdersController.class_eval do
  show.wants.js { render :template => 'admin/orders/show.js.erb', :layout => false }
  update.wants.js { render :template => 'admin/orders/show.js.erb', :layout => false }

  update do
    flash nil
    wants.html do
      if !@order.line_items.empty?
        unless @order.complete?
          if params[:order].key?(:email)
            @order.shipping_method = @order.available_shipping_methods(:front_end).first
            @order.create_shipment!
            user = User.find params[:user_id]
            @order.update_attribute :user_id, user.id unless user.nil?
            raise 'wtf' if user.nil?
            redirect_to edit_admin_order_shipment_path(@order, @order.shipment)
          else
            redirect_to user_admin_order_path(@order)
          end
        else
          redirect_to admin_order_path(@order)
        end
      else
        render :action => :new
      end
    end
  end

  def send_quote
    load_object
    @order.next until @order.state == 'payment'
    OrderMailer.quote_email(@order).deliver
    redirect_to admin_order_url(@order)
  end
end

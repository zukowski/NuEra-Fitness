Admin::ShipmentsController.class_eval do
  update.wants.js { render 'tracking', :layout => false }

  def fire
    success = @shipment.send("#{params[:e]}")
    respond_to do |wants|
      wants.html do
        flash.notice = t(:shipment_updated) if success
        flast[:error] = t(:cannot_perform_operation) unless sucess
        redirect_to :back
      end
      wants.js { render 'shipped_success', :layout => false } if params[:e] == 'ship'
    end
  end
  
  private

  def load_data
    load_object
    @selected_country_id ||= @order.bill_address.country_id unless @order.nil? || @order.bill_address.nil?
    @selected_country_id ||= Spree::Config[:default_country_id]
    @shipping_methods = ShippingMethod.all_available(@order, :back_end, :supplier => @shipment.supplier)
    @states = State.find_all_by_country_id(@selected_country_id, :order => 'name')
    @countries = Country.all
  end
end

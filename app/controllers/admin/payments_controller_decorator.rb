Admin::PaymentsController.class_eval do
  def fire
    load_object
    return unless event = params[:e] and @payment.payment_source
      
    
    respond_to do |wants|
      begin
        success = @payment.payment_source.send("#{event}", @payment)
      rescue Spree::GatewayError => ge
        sucess = false
        @error = ge.message if request.xhr?
        flash[:error] = ge.message unless request.xhr?
      end
      wants.html do
        flash.notice = t('payment_update') if success
        flash[:error] ||= t('cannot_perform_operation') unless success
        redirect_to collection_path
      end
      wants.js { render :template => 'admin/orders/show.js.erb', :layout => false }
    end
  end
end

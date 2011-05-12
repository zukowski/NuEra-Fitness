Admin::AdjustmentsController.class_eval do
  index.wants.js { render :template => "admin/adjustments/index.js.erb", :layout => false }
  update.wants.js { render 'actual_amount', :layout => false }
end

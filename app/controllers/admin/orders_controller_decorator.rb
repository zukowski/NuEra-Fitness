Admin::OrdersController.class_eval do
  show.wants.js { render :template => 'admin/orders/show.js.erb', :layout => false }
  update.wants.js { render :template => 'admin/orders/show.js.erb', :layout => false }
end

Admin::LineItemsController.class_eval do
  update.wants.js { render 'actual_price', :layout => false }
end

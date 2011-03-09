class Admin::SuppliersController < Admin::BaseController
  resource_controller

  update.wants.html { redirect_to collection_url }
end

class Admin::PackagesController < Admin::BaseController
  resource_controller

  create.wants.html { redirect_to edit_object_url }
  update.wants.html { redirect_to edit_object_url }
  update.wants.js   { render :partial => 'admin/packages/package_variants', :locals => {:order => object.reload}, :layout => false }

  update.before do
    if params[:variant_id]
      object.variants << Variant.find(params[:variant_id])
    end
  end
end

class Admin::PackagesController < Admin::BaseController
  resource_controller :singleton
  belongs_to :product

  update.wants.js   { render :partial => 'admin/packages/package_variants', :layout => false }

  update.before do
    if params[:variant_id]
      object.variants << Variant.find(params[:variant_id])
    end
  end

  def remove_variant
    load_object
    @package.variants.delete(Variant.find params[:variant_id])
    @package.reload
    if request.xhr?
      render :partial => 'admin/packages/package_variants.html.erb', :layout => false
    else
      redirect_to @package
    end
  end
end

class Admin::VideosController < Admin::BaseController
	
	respond_to :html

  def index
    params[:search] ||= {}
    @search = Video.metasearch(params[:search])
    
    @videos = Video.metasearch(params[:search]).paginate(
                                   :per_page => Spree::Config[:orders_per_page],
                                   :page => params[:page])
		
    respond_with(@videos)
  end
  
  # we don't want a show method
  resource_controller :except => [ :show ]
	
  # redirect to the edit action after create
  create.response do |wants|
    wants.html { redirect_to edit_admin_video_url( @video ) }
  end

  # redirect to the edit action after update
  update.response do |wants|
    wants.html { redirect_to edit_admin_video_url( @video ) }
  end

end
class Admin::StaticcontentController < ApplicationController
  before_filter :admin_required
  layout 'admin'
  def index
    @all_content = StaticContent.find(:all)
    if params[:static_content_id]
      @static_content = StaticContent.find(params[:static_content_id])
    else
      @static_content = StaticContent.find(:first)
    end
    return unless request.post?
    @static_content.content = params[:content]
    @static_content.save
    flash[:notice] = "Content Saved"
  end

  def get_content
    @static_content = StaticContent.find(params[:static_content_id])
    render :update do |page|
      page['static_content'].value = @static_content.content
    end
  end
end

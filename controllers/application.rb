# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem
	include SslRequirement
	
  def help
    render :partial => "common/help", :layout => "application"
  end
  private
  def get_cart
    session[:cart] ||= Cart.new
  end
end

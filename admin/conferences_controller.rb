class Admin::ConferencesController < ApplicationController
  before_filter :admin_required
  layout 'admin'
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @conference_pages, @conferences = paginate :conferences, :per_page => 10
  end

  def show
    @conference = Conference.find(params[:id])
  end

  def new
    @conference = Conference.new
  end

  def create
    @conference = Conference.new(params[:conference])
    if @conference.save
      flash[:notice] = 'Conference was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @conference = Conference.find(params[:id])
  end

  def update
    @conference = Conference.find(params[:id])
    if @conference.update_attributes(params[:conference])
      flash[:notice] = 'Conference was successfully updated.'
      redirect_to :action => 'show', :id => @conference
    else
      render :action => 'edit'
    end
  end

  def destroy
    @conference = Conference.find(params[:id])
    if @conference.has_purchased
      flash[:error] = "Cannot delete as policy has been issued to user"
    else
      @conference.destroy
    end
    redirect_to :action => 'list'
  end
end

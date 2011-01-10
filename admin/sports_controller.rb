class Admin::SportsController < ApplicationController
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
    @sport_pages, @sports = paginate :sports, :per_page => 10
  end

  def show
    @sport = Sport.find(params[:id])
  end

  def new
    @sport = Sport.new
  end

  def create
    @sport = Sport.new(params[:sport])
    if @sport.save
      flash[:notice] = 'Sport was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @sport = Sport.find(params[:id])
  end

  def update
    @sport = Sport.find(params[:id])
    if @sport.update_attributes(params[:sport])
      flash[:notice] = 'Sport was successfully updated.'
      redirect_to :action => 'show', :id => @sport
    else
      render :action => 'edit'
    end
  end

  def destroy
    @sport = Sport.find(params[:id])
    if @sport.has_purchased
      flash[:error] = "Cannot delete as policy has been issued to user"
    else
      @sport.destroy
    end
    redirect_to :action => 'list'
  end
  
end

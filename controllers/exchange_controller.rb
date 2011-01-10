class ExchangeController < ApplicationController
  before_filter :login_required , :except => [:index, :team, :policy_details]

  def sell
    @errors = []
    @policy = Inventory.find(params[:policy_id])
    @max = @policy.quantity
    if params[:from_form]
      @errors << "Price cannot be empty."    if params[:price] == ""
      @errors << "Quantity cannot be empty."    if params[:quantity] == ""
      @errors << "You need to agree to the terms and service."  if not params[:agreement]
      if @errors.size == 0 
        @quantity = params[:quantity].to_i > @max ?  @max  : params[:quantity].to_i
        PolicyForSale.create(:event_id => @policy.event_id,:quantity => @quantity,
                             :policy_price => params[:price], :user_id => session[:user])
        @policy.quantity =  @policy.quantity - @quantity
        @policy.save
        redirect_to :controller => 'exchange', :action => 'team', :id => @policy.event.team_id
      end
    else
      render :update do |page|
        page.replace_html params[:element], :partial => 'policy', :locals => {:max => @max,:policy => @policy, :suff => params[:suff], :transaction => 'sell'} 
      end
    end
  end

  def remove_policy_from_exchange
    @policy_for_sale = PolicyForSale.find(params[:policy_id])
    @event = @policy_for_sale.event
    @inventory = Inventory.find(:first, :conditions => ["event_id = ? and user_id = ? AND is_active = 1",
                                 @event.id, session[:user] ])
    @inventory.quantity =  @inventory.quantity + @policy_for_sale.quantity 
    @inventory.save
    @policy_for_sale.destroy
    redirect_to :controller => 'exchange', :action => 'team', :id => @policy_for_sale.event.team_id
  end

  def update
    @errors = []
    @policy_for_sale = PolicyForSale.find(params[:policy_id])
    @event = @policy_for_sale.event
    @max = Inventory.find(:first, :conditions => ["event_id = ? and user_id = ? AND is_active = 1", 
                          @event.id, session[:user] ]).quantity + @policy_for_sale.quantity
    if params[:from_form]
      @errors << "Price cannot be empty"    if params[:price] == ""
      @errors << "Quantity cannot be empty"    if params[:quantity] == ""
      @errors << "You need to agree to terms and service"  if not params[:agreement]
      @quantity = params[:quantity].to_i > @max ?  @max  : params[:quantity].to_i
      @old_quantity = @policy_for_sale.quantity
      @policy_for_sale.quantity = @quantity
      @policy_for_sale.policy_price = params[:price]
      if @errors.size == 0 
        @policy_for_sale.save
        @inventory = Inventory.find(:first, :conditions => ["event_id = ? and user_id = ? AND is_active = 1",
                                     @event.id, session[:user] ])
        @inventory.quantity =  @inventory.quantity - (@quantity - @old_quantity)
        @inventory.save
        redirect_to :controller => 'exchange', :action => 'team', :id => @policy_for_sale.event.team_id
      end
    else
      render :update do |page|
        page.replace_html params[:element], :partial => 'policy', :locals => {:max => @max,:policy => @policy_for_sale, :suff => params[:suff], :transaction => 'update'} 
      end
    end
  end

  def index
    @event = Event.find(params[:event_id])
    session[:event_id] = params[:event_id]
    session[:team_id] = nil
    @policies = PolicyForSale.find(:all, :conditions => ["event_id = ? AND quantity > 0 AND is_active = 1", 
                                   params[:event_id]])
    @your_policies = @event.num_policies_for_sale(session[:user])  if session[:user]
  end

  def team
    @team = Team.find(params[:id])
    events = Event.find(:all, :conditions => ['team_id = ? AND is_active = 1', @team.id])
    @policies = []
    @listed_policies = []
    @listed_policies_with_quantity = []
    @inventory = []
    for event in events
      if session[:user]
        order_frag = "id"
        if params[:sort]
            order_frag = 'quantity'  if params[:c] == 'policy'
            order_frag = 'policy_price'  if params[:c] == 'price'
            order_frag += ' DESC'   if params[:sort] == 'up'
        end
        @policies += PolicyForSale.find(:all, :conditions => ['event_id = ? AND quantity > 0 and user_id != ? and is_active = 1', event.id,session[:user]], :order => order_frag)
        @listed_policies_with_quantity += PolicyForSale.find_by_sql ["SELECT SUM(p.quantity) as net_quantity,p.*  FROM policy_for_sales as p  WHERE user_id = ? and event_id = ? AND is_active = 1 AND quantity > 0 GROUP BY event_id", session[:user],event.id]
        @listed_policies += PolicyForSale.find_by_sql ["SELECT p.*  FROM policy_for_sales as p  WHERE user_id = ? and event_id = ? AND is_active = 1 AND quantity > 0 ORDER BY p.#{order_frag}", session[:user],event.id]
        @inventory += Inventory.find(:all, :conditions => ["event_id = ? and user_id = ? AND quantity > 0 and is_active = 1",
                                     event.id, session[:user] ])
      else
        @policies += PolicyForSale.find(:all, :conditions => ['event_id = ? AND quantity > 0 AND is_active = 1', event.id])
      end
    end
  end
  
  def policy_details
    @policy = PolicyForSale.find(params[:id])
  end
  def sell_form
  end

  def update_form
  end
end

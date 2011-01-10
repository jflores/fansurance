class StoreController < ApplicationController
  #layout 'billing'
  before_filter :login_required, :except => [:buy,:delete_item, :show_cart,:change_item_count, :add_gift, :modify_gift]
  ssl_required :checkout,  :process_checkout  
  def buy
    @cart = get_cart
    from_fansurance = true
    if params[:policy_for_sale_id]
      from_fansurance = false
      @policy = PolicyForSale.find(params[:policy_for_sale_id])
      @event = @policy.event
      @quantity = @policy.quantity
    else
      @event = Event.find(params[:event_id])
      @quantity = params[:quantity].to_i
    end
    max_user_policies = @event.max_user_policies
    @flag = true

    if session[:user]
      @inventory = Inventory.find_by_sql ["SELECT (IFNULL(SUM(quantity),0) +   0) AS quantity FROM 
        inventories WHERE user_id = #{session[:user]} AND event_id = #{@event.id} AND is_active = 1"]
      @policy_for_sale = PolicyForSale.find_by_sql ["SELECT (IFNULL(SUM(quantity),0) +   0) AS quantity FROM 
        policy_for_sales WHERE user_id = #{session[:user]} AND event_id = #{@event.id} AND is_active = 1"]
      if @inventory[0].quantity + @policy_for_sale[0].quantity + @quantity > max_user_policies
        flash[:error] = "You can have only #{max_user_policies} policies of #{@event.name}"
        @flag = false
      end
      purchased_inventory = @inventory[0].quantity + @policy_for_sale[0].quantity
    else
      purchased_inventory = 0
    end
    

    prev_quantity = 0
    @prev_items = @cart.items.select {|i| i.event_id == @event.id}
    @prev_items.each do |p|
      prev_quantity = prev_quantity + p.quantity
    end

    #when a person add the same policy as one already in cart  
    #see if there are enough policies available
    if from_fansurance
      if @event.num_policies < @quantity + prev_quantity
        flash[:error] = "Sorry, please choose a lower no of policies as 
        the policies available is not enough"
        @flag = false
      end
    end
    if  @quantity + prev_quantity > max_user_policies
      flash[:error] = "You can have only #{max_user_policies} policies of #{@event.name}"
      @flag = false
    end
    if prev_quantity + purchased_inventory + @quantity > max_user_policies
      flash[:error] = "You can have only #{max_user_policies} policies of #{@event.name}"
      @flag = false
    end

    if from_fansurance
      @cart.add(@event,@quantity,from_fansurance) if @flag
    else
      @cart.add(@policy,@quantity,from_fansurance) if @flag
    end
    redirect_to(:action => 'show_cart')
  end
  
  def show_cart
    @cart = get_cart
    @items = @cart.items
    if @items.empty? && !flash[:error]
      flash[:notice] = "No policies are presently in your cart."
      #redirect_to :controller => 'site', :action => 'index'
    end
  end
  
  def delete_item
    @cart = get_cart
    @item = @cart.items[params[:id].to_i]
    @cart.total_price = @cart.total_price - @item.price * @item.quantity
    @cart.items.delete_at(params[:id].to_i)
    redirect_to(:action => 'show_cart')
  end

  def add_gift
    @cart = get_cart
    item = @cart.items[params[:id].to_i]
    @errors = []
    if (params[:email_1] == "" || params[:email_2] == "" )
      @errors << "Recipient email and confirmation email are both necessary."
    end
    if params[:email_1] != params[:email_2]
      @errors << "Recipient email and confirmation email do not match."
    end
    if (!params[:quantity] ||  params[:quantity] == "") && item.from_fansurance
      @errors << "Gift quantity is necessary."
    end
    if params[:name] == ""
      @errors << "Recipient name is necessary."
    end

    if @errors.size == 0
     quantity = item.from_fansurance  ? params[:quantity] : item.quantity
     @cart.add_gift(params[:id],quantity,params[:note],params[:email_1],params[:name])
     redirect_to :action => :show_cart
    else
     @items = @cart.items
     render :action => :show_cart
    end
  end

  def modify_gift
    @cart = get_cart
    @errors = []
    if (params[:email_1] == "" || params[:email_2] == "" )
      @errors << "Recipient email and confirmation email are both necessary."
    end
    if params[:email_1] != params[:email_2]
      @errors << "Recipient email and confirmation email do not match."
    end
    if params[:name] == ""
      @errors << "Recipient name is necessary."
    end

    if @errors.size == 0
      @item = @cart.items[params[:id].to_i]
      policy_gift = @item.policy_gift 
      policy_gift.note = params[:note]
      policy_gift.receiver_name = params[:name]
      policy_gift.receiver_email = params[:email_1]
      user = User.find(:first, :conditions => ["email = ?",  params[:email_1]])
      policy_gift.receiver_id = user ? user.id : nil
      policy_gift.save
      redirect_to :action => :show_cart
    else
     @items = @cart.items
     render :action => :show_cart
    end
  end
    

  def change_item_count
    @cart = get_cart
    @item = @cart.items[params[:item_id].to_i]
    if  params[:new_quantity].to_i > @cart.items[params[:item_id].to_i].quantity
      difference = params[:new_quantity].to_i - @cart.items[params[:item_id].to_i].quantity.to_i
      redirect_to :action => 'buy', :event_id => @item.event_id, :quantity => difference
    else
      @cart.total_price = @cart.total_price - @item.price * @item.quantity
      @cart.total_price = @cart.total_price + @item.price * params[:new_quantity].to_i
      @cart.items[params[:item_id].to_i].quantity = params[:new_quantity].to_i
      redirect_to(:action => 'show_cart')
    end
  end
  
  def checkout
    @errors = process_cart
    @cart = get_cart
    @items = @cart.items
    @order = Order.new

    @card = CreditCard.new
    @card.expire_month = Date.today.month
    @card.expire_year = Date.today.year

    @user = User.find(session[:user])
    @order.shipping_same_as_billing = params[:order] ? ( params[:order][:shipping_same_as_billing] ? true : false) : true
    @order.shipping_firstname = @user.shipping_firstname
    @order.shipping_lastname = @user.shipping_lastname
    @order.shipping_address1 = @user.shipping_address1
    @order.shipping_address2 = @user.shipping_address2
    @order.shipping_city = @user.shipping_city
    @order.shipping_state = @user.shipping_state
    @order.shipping_zip = @user.shipping_zip
    @order.billing_address1 = @user.shipping_address1
    @order.billing_address2 = @user.shipping_address2
    @order.billing_city = @user.shipping_city
    @order.billing_state = @user.shipping_state
    @order.billing_zip = @user.shipping_zip
  end

  
  def process_checkout
    logger.debug "Processing Start"
    @cart = get_cart
    @items = @cart.items
    @errors = process_cart
    @card = CreditCard.new(params[:card])
    if @errors.size != 0
      logger.debug "We have some errors returning before doing a damn thing"
      render :action => 'checkout'
      return
     end
    case request.method
    when :post
      @order = Order.new(params[:order])
      @order.shipping_same_as_billing = false if !params[:order][:shipping_same_as_billing]
      @order.billing_firstname = params[:card][:firstname]
      @order.billing_lastname = params[:card][:lastname]
      @order.user_id = session[:user]
      @order.order_items << @items
      @order.total_price = @cart.total_price
      
      @amount = @order.total_price
      
      
      begin 
        state = State.find(:first, :conditions => ['code = ?', @order.billing_state.upcase])
        if !state
          @errors << "State is not valid"
          render :action => 'checkout'
          return
        end
      rescue
        @errors << "State is not valid"
        render :action => 'checkout'
        return
      end


      if @order.valid?
        @order.save
        @cc = CreditCard.new(:number => params[:card][:number],
                       :expire_month => params[:card][:expire_month],
                       :expire_year => params[:card][:expire_year],
                       :cardType => params[:card][:cardType],
                       :address1 => @order.billing_address1,
                       :address2 => @order.billing_address2,
                       :city =>  @order.billing_city,
                       :state =>  @order.billing_state,
                       :zip =>  @order.billing_zip,
                       :cvv2 => params[:card][:cvv2],
                       :email => @order.user.email,
                       :firstname => @order.billing_firstname,
                       :lastname => @order.billing_lastname,
                       :order_id => @order.id)
        
        unless @card.valid?
              logger.debug "Credit Card not valid"
              render :action => 'checkout'
              return
        end
        @cc.save

        @cart.empty!
        redirect_to :action => 'view_order', :id => @order.id
      else
        logger.debug "ORDER NOT VALID"
        render :action => 'checkout'
      end
    end
  end

  def view_order
    @order = Order.find(params[:id])
    @items = @order.order_items
  end
  
  def get_order_status
    @order = Order.find(params[:id])
    render :partial => 'get_order_status'
  end

  private
  
  def process_cart
    @errors = []
    @cart = get_cart
    @cart.items.each do |i|
      i.event.reload
      @event = i.event
      max_user_policies = @event.max_user_policies
      @inventory = Inventory.find_by_sql ["SELECT (IFNULL(SUM(quantity),0) +   0) AS quantity FROM 
        inventories WHERE user_id = #{session[:user]} AND event_id = #{@event.id} AND is_active = 1"]
      @policy_for_sale = PolicyForSale.find_by_sql ["SELECT (IFNULL(SUM(quantity),0) +   0) AS quantity FROM 
        policy_for_sales WHERE user_id = #{session[:user]} AND event_id = #{@event.id} AND is_active = 1"]
      purchased_inventory = @inventory[0].quantity + @policy_for_sale[0].quantity
      prev_quantity = 0
      @prev_items = @cart.items.select {|i| i.event_id == @event.id}
      @prev_items.each do |p|
        prev_quantity = prev_quantity + p.quantity
      end

      #when a person add the same policy as one already in cart  
      #see if there are enough policies available
      # This won't work as prev_quantity includes policies from exchange also
      #if i.from_fansurance
      #  if @event.num_policies < prev_quantity
      #    @errors << "Sorry, please choose a lower number of policies for #{@event.name}
      #                there are not enough policies available at this time"
      #  end
      #end
      if prev_quantity + purchased_inventory  > max_user_policies
        @errors << "You can have only #{max_user_policies} policies of one event. Update #{@event.name} accordingly "
      end
    end
    return @errors
  end
end

class AccountController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  # If you want "remember me" functionality, add this before_filter to Application Controller
  before_filter :login_from_cookie
  observer :user_observer

  # say something nice, you goof!  something sweet.
  def index
    redirect_to(:action => 'login') unless logged_in?   
  end

  def profile
    @user = User.find(self.current_user.id)
    @inventory = @user.policy_inventory
    @listed_policies = @user.policy_for_sale
    @sold_policies = @user.policy_sold
    @inactive_policies = @user.inactive_policies
    @gifts_given = @user.gifts_given
    @gifts_received = @user.gifts_received
    @gifts_claimed = @user.gifts_claimed
  end
  
  
  def policydetails 
    @policy = Inventory.find(params[:id])
  end
  
  def printpolicy
    @policy = Inventory.find(params[:id])
    render :partial => 'printpolicy', :layout => false
  end
  
  def get_team_list
    if !params[:conference_id].nil?
      @sport = Sport.find(params[:sport_id], :include => :conferences)
      @teams = Team.find(:all, :conditions => ["conference_id = ?", params[:conference_id]])
          
     render :update do |page|
        page[:begin].replace_html :partial => "begin_button", :locals => {:conference => Conference.find(params[:conference_id]),:sport => @sport, :team => Team.find(:first, :conditions => ["conference_id = ?", @sport.conferences[0]]), :exchange => true}
        page[:conference_list].replace_html  :partial => 'conference_list', :locals => {:conference => Conference.find(params[:conference_id]), :conferences => @sport.conferences, :sport => @sport}
        page[:team_list].replace_html :partial => 'team_list', :locals => {:sport => @sport, :teams => @teams}
      end 
    elsif !params[:sport_id].nil?
      begin
        @sport = Sport.find(params[:sport_id], :include => :conferences)
        if @sport.conferences.size > 0
          render :update do |page|
            page[:begin].replace_html :partial => "begin_button", :locals => {:team => Team.find(:first, :conditions => ["conference_id = ?", @sport.conferences[0]]),:exchange => true}
            page[:conference_list].replace_html  :partial => 'conference_list', :locals => {:conference => @sport.conferences[0], :conferences => @sport.conferences, :sport => @sport}
            page[:team_list].replace_html :partial => 'team_list', :locals => {:sport => @sport, :teams => Team.find(:all, :conditions => ["conference_id = ?", @sport.conferences[0].id])}
            #page.replace_html 'conference_list', :partial => 'conference_list', :locals => {:conferences => @sport.conferences}
            end 
        else
          @teams = Team.find(:all, :conditions => ["sport_id = ?", params[:sport_id]])
          
          render :update do |page|
            page[:begin].replace_html :partial => "begin_button", :locals => {:sport => @sport, :team => Team.find(:first, :conditions => ["sport_id = ?", params[:sport_id]]), :exchange => true}
            page[:conference_list].replace_html  ''
            page[:team_list].replace_html :partial => 'team_list', :locals => {:sport => @sport, :teams => Team.find(:all, :conditions => ["sport_id = ?", params[:sport_id]])}
          end 
        end
      rescue
        render :nothing => true
      end

    else
    end
  end
  
  def get_begin_button
    begin
      session[:team_id] = params[:team_id]
      session[:event_id] =  nil
      team_id = params[:team_id] 
      sport_id = params[:sport_id]
      sport = nil
      team = nil
      any_team = false
      logger.debug "any_team = #{any_team} team_id = #{team_id}"
      begin
        if team_id == "-1"
          any_team = true
        else 
          team = Team.find(team_id)
        end 
      rescue 
      end
    
      begin
        sport = Sport.find(sport_id)
        unless team 
          team = Team.find(:first, :conditions => ['sport_id = ?', sport.id]);
        end
      rescue 
      end
    
      logger.debug "any_team = #{any_team}"
      render :partial => 'begin_button', :locals => { :team => team, :sport => sport, :any_team => any_team}
    rescue
      render :partial => 'begin_button'
    end
  end

  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:email], params[:password])
    current_user = self.current_user
    if logged_in?
      self.current_user.last_logged_in = Time.now
      # Hack
      self.current_user.email_confirmation = self.current_user.email
      self.current_user.save!
      # end Hack
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      if self.current_user.is_admin
        redirect_to :controller => 'site', :action => 'admin_index'
      else
        redirect_back_or_default(:controller => '/site', :action => 'index')
      end
      flash[:notice] = "Login successful."
    else
      flash[:error] = "Login Failed. Username and/or password is invalid."
    end
  end

  def signup
    @errors = false
    @user = User.new(params[:user])
    return unless request.post?
    @user.save!
    self.current_user = @user
    # Set all the policies with this user's email with the correct user id
    ActiveRecord::Base.connection.execute "UPDATE policy_gifts SET receiver_id = #{@user.id} WHERE  receiver_email = '#{@user.email}'" 
    redirect_back_or_default(:controller => '/account', :action => 'index')
    flash[:notice] = "Thanks for signing up!"
  rescue ActiveRecord::RecordInvalid
    @errors = true
    render :action => 'signup'
  end

  
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(:controller => '/account', :action => 'index')
  end


  def reset_password
    @user = User.find_by_password_reset_code(params[:id]) if params[:id]
    @show_fields = true
    raise if @user.nil?
    return if @user unless (params[:user] && params[:user][:password] != "" )
      if (params[:user][:password] == params[:user][:password_confirmation])
        self.current_user = @user #for the next two lines to work
        @user.password_confirmation = params[:user][:password_confirmation]
        @user.password = params[:user][:password]
        @user.email_confirmation = @user.email
        @user.password_reset_code = nil
        @user.reset_password
        flash[:message] = @user.save ? "Password reset" : "Password not reset" 
        self.current_user = User.authenticate(@user.email, params[:user][:password])
        if logged_in?
          if self.current_user.is_admin
            redirect_to :controller => 'site', :action => 'admin_index'
          else
            redirect_back_or_default(:controller => '/site', :action => 'index')
          end
        else
          redirect_back_or_default(:controller => '/account', :action => 'login') 
        end
      else
        flash[:error] = "Password mismatch" 
        return
      end  
    rescue
      logger.error "Invalid Reset Code entered" 
      flash[:error] = "Sorry - That is an invalid/expired password reset link. Please check the link and try again." 
      @show_fields = false
      #redirect_back_or_default(:controller => '/account', :action => 'login')
    end

  def forgot_password
    return unless request.post?
    if @user = User.find_by_email(params[:email])
      @user.email_confirmation = params[:email]
      @user.forgot_password
      @user.save
      flash[:message] = "A password reset link has been sent to your email address." 
      redirect_to :controller => '/account', :action => 'login'
    else
      flash[:error] = "That email address is not on file." 
    end
  end

  def edit
    @user = User.find(self.current_user.id)
    @user.email_confirmation = @user.email
    @user.shipping_firstname = @user.shipping_firstname.empty? ?  @user.firstname :  @user.shipping_firstname 
    @user.shipping_lastname = @user.shipping_lastname.empty? ?  @user.lastname :  @user.shipping_lastname 
  end

    #
    #update the user table
  def update
    @user = User.find(self.current_user.id)
    if @user.update_attributes(params[:user])
        flash[:notice] = 'User was successfully updated.'
        redirect_to :action => 'profile'
    else
        render :action => 'edit'
    end
  end

  def modify_gift
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
      policy_gift = PolicyGift.find(params[:id])
      policy_gift.note = params[:note]
      policy_gift.receiver_name = params[:name]
      policy_gift.receiver_email = params[:email_1]
      user = User.find(:first, :conditions => ["email = ?",  params[:email_1]])
      policy_gift.receiver_id = user ? user.id : nil
      policy_gift.save
      UserNotifier.deliver_claim_gift(policy_gift.receiver_email)
      redirect_to :action => :profile
    else
     @edit = true
     @policy_gift = PolicyGift.find(params[:id])
     render :action => :claim_policy
    end
  end

  def claim_policy
    @policy_gift = PolicyGift.find(params[:id])
    return unless request.post?
    Inventory.create(:event_id => @policy_gift.event_id, :quantity => @policy_gift.quantity, :policy_price => @policy_gift.policy_price, :user_id => session[:user], :from_exchange => false)
    @policy_gift.is_claimed = true
    @policy_gift.save
    redirect_to :action => :profile
  end
end

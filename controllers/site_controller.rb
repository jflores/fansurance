class SiteController < ApplicationController
  before_filter :login_required, :only => [:my_orders, :my_policies]
  layout "application"
  def index
    @css_header = "home"
    
  end

  def admin_index
    #render :template => 'site/index', :layout => 'admin'
    render :template => 'site/admin_index', :layout => 'admin'
  end


  def my_orders
    @orders = Order.find(:all, :conditions => ["user_id = ?",session[:user]])
  end
  
  def eventdetails
    @event = Event.find(params[:id])
    @policyterms = StaticContent.find(:first, :conditions => ["page_name = 'policy_terms'"]).content
  end

  def get_team_list
    if !params[:conference_id].nil? && params[:conference_id] != ""
    
      @sport = Sport.find(params[:sport_id], :include => :conferences)
      @teams = Team.find(:all, :conditions => ["conference_id = ?", params[:conference_id]])
          
     render :update do |page|
        page[:begin].replace_html :partial => "begin_button", :locals => {:conference => Conference.find(params[:conference_id]),:sport => @sport, :team => nil }
        page[:conference_list].replace_html  :partial => 'conference_list', :locals => {:conference => Conference.find(params[:conference_id]), :conferences => @sport.conferences, :sport => @sport}
        page[:team_list].replace_html :partial => 'team_list', :locals => {:sport => @sport, :teams => @teams, :any_team => true}
      end 
    elsif !params[:sport_id].nil?
    
      begin
        @sport = Sport.find(params[:sport_id], :include => :conferences)
        @teams = Team.find(:all, :conditions => ["sport_id = ?", params[:sport_id]])
          render :update do |page|
            page[:begin].replace_html :partial => "begin_button", :locals => {:sport => @sport, :any_team => true}
              if @sport.conferences.size > 0
                  page[:conference_list].replace_html  :partial => 'conference_list', :locals => {:conference => nil, :conferences => @sport.conferences, :sport => @sport}
              else
                  page[:conference_list].replace_html  ''
              end
            page[:team_list].replace_html :partial => 'team_list', :locals => {:sport => @sport, :teams => @teams}
        end 
      rescue
      
        render :nothing => true
      end

    else
	    
    end
  end
  
  def get_events_list
    begin
      session[:team_id] = params[:team_id]
      session[:event_id] =  nil
      @events = Event.find(:all, :conditions => ["team_id = ? AND is_active = 1", params[:team_id]])
      @team = Team.find(params[:team_id])
      render :partial => 'events_list'
    rescue
      render :nothing => true
    end
  end
  
  def events
      session[:team_id] = params[:team_id]
      session[:event_id] =  nil
      @team_instruction =  StaticContent.find(:first, :conditions => ["page_name = 'team_instructions'"]).content
      if params[:team_id].nil?
        if !params[:sport_id].nil?
          @sport = Sport.find(params[:sport_id], :include => :conferences)
          if @sport.conferences.size > 0
            conf_id = params[:conference_id] || @sport.conferences[0].id
            @teams = Team.find(:all, :conditions => ['conference_id = ?', conf_id])
            @events = []
            if @teams.size > 0
              @team = @teams.first
              @events += Event.find(:all, :conditions => ["team_id = ? and is_active = 1", @teams.first.id])	         
            end	
            @policies_in_exchange = []
            @total_policies_in_exchange = 0
            for event in @events
              @policies_in_exchange += PolicyForSale.find(:all, :conditions => ['policy_for_sales.event_id = ? AND policy_for_sales.quantity > 0 and policy_for_sales.is_active = 1', event.id])
            end 
            for policy in @policies_in_exchange
              @total_policies_in_exchange += policy.quantity
            end
            
            render :partial => "team_browse_conf", :layout => "application"

          else 
            @teams = Team.find(:all, :conditions => ['sport_id = ?', @sport.id])
            @events = []
            if @teams.size > 0
              @events += Event.find(:all, :conditions => ["team_id = ? and is_active = 1", @teams.first.id])
            @team = @teams.first
            end 
            @policies_in_exchange = []
            @total_policies_in_exchange = 0
            for event in @events
              @policies_in_exchange += PolicyForSale.find(:all, :conditions => ['policy_for_sales.event_id = ? AND policy_for_sales.quantity > 0 AND  policy_for_sales.is_active = 1', event.id])
            end 
            for policy in @policies_in_exchange
              @total_policies_in_exchange += policy.quantity
            end
            render :partial => "team_browse", :layout => "application"
          end
        end
      else 
        @events = Event.find(:all, :conditions => ["team_id = ? AND is_active = 1", params[:team_id]])
        @team = Team.find(params[:team_id])
        @policies_in_exchange = []
        @total_policies_in_exchange = 0
        for event in @events
          @policies_in_exchange += PolicyForSale.find(:all, :conditions => ['policy_for_sales.event_id = ? AND policy_for_sales.quantity > 0 AND policy_for_sales.is_active = 1', event.id])
        end 
        for policy in @policies_in_exchange
          @total_policies_in_exchange += policy.quantity
        end
      end
  end
  
  def change_sports
    @sport = Sport.find(params[:sport_id], :include => 'conferences')
    @teams = Team.find(:all, :conditions => ['sport_id = ?', params[:sport_id]])
    if !params[:conferences].nil? && params[:conferences] != 0
     # render :partial => "team_browse_conf", :layout => "application"
     render :update do |page|
      page.edirect_to :action => 'events', :sport_id => @sport.id, :conferences => 1
     end
    else
      render :update do |page|
        page.redirect_to :action => 'events', :sport_id => @sport.id
      end
      #render :partial => "team_browse", :layout => "application"
    end
  end
  
  def get_team_info
    @team = Team.find(params[:id])
    @events = Event.find(:all, :conditions => ["team_id = ? AND is_active = 1", @team.id])
    @policies_in_exchange = []
    @total_policies_in_exchange = 0
	@team_instruction =  StaticContent.find(:first, :conditions => ["page_name = 'team_instructions'"]).content
    for event in @events
      @policies_in_exchange += PolicyForSale.find(:all, :conditions => ['policy_for_sales.event_id = ? AND policy_for_sales.quantity > 0 AND  policy_for_sales.is_active = 1', event.id])
    end
    for policy in @policies_in_exchange
      @total_policies_in_exchange += policy.quantity
    end
    teams = nil
    if @team.sport.conferences.size > 0
      teams = Team.find(:all, :include => :conference, :conditions => ['teams.sport_id = ? AND conferences.id = ?', @team.sport.id, @team.conference.id])
    else 
      teams = Team.find(:all, :conditions => ['sport_id = ?', @team.sport.id])
    end
    
    teams ||= []
    
    render :update do |page|
      page['team_browse_spec'].replace :partial => 'team_browse_spec', :locals => {:team => @team}, :layout => false
      page['team_browse_teams'].reload :locals => {:selected_team => @team, :teams =>  teams}
      page['share_team'].reload :locals => {:team => @team}
    end
  end
  
  def get_conf_teams
    @conference = Conference.find(params[:id])
    @sport = @conference.sport
    @teams = Team.find(:all, :conditions => ['conference_id = ?', params[:id]])
	@team_instruction =  StaticContent.find(:first, :conditions => ["page_name = 'team_instructions'"]).content
    @events = []
    for team in @teams 
	  @events += Event.find(:all, :conditions => ["team_id = ? AND is_active = 1", @teams.first.id])
	 # This next line would add all of the events together which would result in policies in the exchange that did not exist
	 # For example if Spain-Barcelona had a policy in the exchange and Spain-Madrid did not, the Spain-Madrid page would show policy exchange listings
	 # Not sure if there are any side effects...? 
     # @events += Event.find(:all, :conditions => ["team_id = ? AND is_active = 1", team.id])
    end
    @policies_in_exchange = []
    @total_policies_in_exchange = 0
    for event in @events
      @policies_in_exchange += PolicyForSale.find(:all, :conditions => ['policy_for_sales.event_id = ? AND policy_for_sales.quantity > 0 AND  policy_for_sales.is_active = 1', event.id])
    end 
    for policy in @policies_in_exchange
      @total_policies_in_exchange += policy.quantity
    end
    render :update do |page|
      page['team_browse_conf_confs'].reload :locals => {:selected_conf => @conference, :sport => @sport }
      if @teams.size > 0
        page['team_browse_spec'].replace_html :partial => 'team_browse_spec', :locals => {:team => @teams[0], :total_policies_in_exchange => @total_policies_in_exchange, :policies_in_exchange => @policies_in_exchange}, :layout => false
      else 
        page['team_browse_spec'].replace_html ''
      end
      page['team_browse_teams'].reload :locals => {:selected_team => @teams.first, :teams => @teams }
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
  
  def continue_shopping
    if session[:team_id] 
      team = Team.find(session[:team_id])
      redirect_to :controller => 'site', :action => 'events', :team_id => team.id
    elsif session[:event_id]
      team = Event.find(session[:event_id]).team
      redirect_to :controller => 'site', :action => 'events', :team_id => team.id
    else
      redirect_to :action=>'index'
    end
  end

  def my_policies
    @user = User.find(session[:user])
    @inventory = @user.policy_inventory
    @for_sale =  @user.policy_for_sale
    @sold_policy = []
    @inactive_policies = []
  end

  def view_policy
    @order_item = OrderItem.find(params[:id])
    @event = @order_item.event
  end
  def share_team
    #@team = Team.find(params[:id])
    @gift_instructions = StaticContent.find(:first, :conditions => ["page_name = 'gift_instructions'"]).content
  end

  def share_policy
    #@team = Team.find(params[:id])
    return unless request.post?
    if( params[:note] == "" || params[:email] == "" || params[:email_friend] == "" || params[:name_friend] == "" ||
       params[:name] == "")
      flash[:error] = "All fields are necessary"
    else
      flash[:error] = nil
      UserNotifier.deliver_share_team(params[:email], params[:name],params[:name_friend],params[:email_friend],
                                      params[:note], params[:id])
      flash[:notice] = "Email sent to #{params[:email_friend]}"
    end

  end

  def about_us
    @content = StaticContent.find(:first, :conditions => ["page_name = 'about_us'"]).content
  end

  def contact_us
    @content = StaticContent.find(:first, :conditions => ["page_name = 'contact_us'"]).content
  end

  def the_gurantee
    @content = StaticContent.find(:first, :conditions => ["page_name = 'the_gurantee'"]).content
  end

  def faq
    @content = StaticContent.find(:first, :conditions => ["page_name = 'faq'"]).content
  end

  def legal
    @content = StaticContent.find(:first, :conditions => ["page_name = 'legal'"]).content
  end

  def news
    @content = StaticContent.find(:first, :conditions => ["page_name = 'news'"]).content
  end
  
  def help
      @content = StaticContent.find(:first, :conditions => ["page_name = 'help'"]).content
  end
                            
end

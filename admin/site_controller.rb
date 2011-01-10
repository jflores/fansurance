class Admin::SiteController < ApplicationController
  layout 'admin'
  def change_commission
    @event = Event.find(:first)
    return unless request.post?
    if params[:commission]
      ActiveRecord::Base.connection.execute "UPDATE events SET commission = #{params[:commission]}"
      @event = Event.find(:first)
      flash[:notice] = 'Commission Updated'
    end
  end
  
  def get_team_list
    if !params[:conference_id].nil? && params[:conference_id] != ""
      @sport = Sport.find(params[:sport_id], :include => :conferences)
      @teams = Team.find(:all, :conditions => ["conference_id = ?", params[:conference_id]])
          
     render :update do |page|
        page[:conference_list].replace_html  :partial => 'admin/events/conference_list', :locals => {:conference => Conference.find(params[:conference_id]), :conferences => @sport.conferences, :sport => @sport}
        page[:team_list].replace_html :partial => 'admin/events/team_list', :locals => {:sport => @sport, :teams => @teams, :any_team => true}
      end 
    elsif !params[:sport_id].nil?
      begin
        @sport = Sport.find(params[:sport_id], :include => :conferences)
        @teams = Team.find(:all, :conditions => ["sport_id = ?", params[:sport_id]])
          render :update do |page|
              if @sport.conferences.size > 0
                  page[:conference_list].replace_html  :partial => 'admin/events/conference_list', :locals => {:conference => nil, :conferences => @sport.conferences, :sport => @sport}
              else
                  page[:conference_list].replace_html  ''
              end
            page[:team_list].replace_html :partial => 'admin/events/team_list', :locals => {:sport => @sport, :teams => @teams, :no_begin => params[:no_begin]}
        end 
      rescue
        render :nothing => true
      end

    else
    end
  end
end

class Admin::EventsController < ApplicationController
  layout 'admin'
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @event_pages, @events = paginate :events, :per_page => 10
  end

  def show
    @event = Event.find(params[:id])
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(params[:event])
    @event.team_id = params[:team_id]
    if params[:team_id] && params[:team_id] != "" && @event.save
      flash[:notice] = 'Event was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @event = Event.find(params[:id])
  end

  def update
    @event = Event.find(params[:id])
    @event.team_id = params[:team_id]
    if @event.update_attributes(params[:event])
      flash[:notice] = 'Event was successfully updated.'
      redirect_to :action => 'show', :id => @event
    else
      render :action => 'edit'
    end
  end

  def destroy
    @event = Event.find(params[:id])
    if @event.has_purchased
      flash[:error] = "Cannot delete as policy has been issued to user"
    else
      @event.destroy
    end
    redirect_to :action => 'list'
  end

  def deactivate
    deactivate_event(params[:id])
    redirect_to :action => 'list'
  end

  def deactivate_event(event_id)
    ActiveRecord::Base.connection.execute "UPDATE policy_for_sales p,inventories i
      SET i.quantity=p.quantity + i.quantity,
        i.is_active=0,p.is_active=0 WHERE
      i.event_id = p.event_id AND 
      i.user_id = p.user_id AND
      i.event_id = #{event_id}"
    ActiveRecord::Base.connection.execute "UPDATE policy_for_sales SET quantity = 0,is_active = 0
      WHERE event_id =  #{event_id}"
    ActiveRecord::Base.connection.execute "UPDATE inventories SET is_active = 0
          WHERE event_id =  #{event_id}"
    ActiveRecord::Base.connection.execute "UPDATE events SET is_active = 0
          WHERE id =  #{event_id}"
  end

  def activate
    ActiveRecord::Base.connection.execute "UPDATE inventories SET is_active = 1
          WHERE event_id =  #{params[:id]}"
    ActiveRecord::Base.connection.execute "UPDATE events SET is_active = 1
          WHERE id =  #{params[:id]}"
    redirect_to :action => 'list'
  end

  def show_owners
    @users = User.find_by_sql("SELECT u.*,i.order_item_id FROM users AS u , inventories as i
                              WHERE u.id = i.user_id AND i.event_id = #{params[:id]}
                              AND i.quantity > 0 ")
  end

  def csv_import
    @errors = []
    if params[:attachment] != "" and params[:attachment]
      path = File.expand_path("#{RAILS_ROOT}/uploads/csv_files/tmp")

      if !File.exists?(File.dirname(path))
        FileUtils.mkdir_p(File.dirname(path))
      end

      attachment_tmp = params[:attachment]
      orig_filename = File.basename(attachment_tmp.original_filename).gsub(/[^\w._-]/, '')
      extension = File.extname(orig_filename).to_s.downcase
      filename = Time.now.to_i.to_s + extension 
      if extension != ".csv"
        @errors << "Only csv files accepted"
      else
        finalpath = File.expand_path("#{RAILS_ROOT}/uploads/csv_files/#{filename}")
        full_path = "#{RAILS_ROOT}/uploads/csv_files/#{filename}"

        if attachment_tmp.instance_of?(Tempfile)
          FileUtils.copy(attachment_tmp.local_path, finalpath)
        else
          File.open(finalpath, "wb") { |f| f.write(attachment_tmp.read) }
        end
        FileUtils.chmod 0755, finalpath
        count = 0
        FasterCSV.foreach(finalpath) do |row|
          @sport = @conference = @team = @event = nil
          if count > 0
            row_no = count - 1
            if row[0] == nil || row[2] == nil || row[3] == nil || row[4] == nil || row[5] == nil || row[6] == nil
              @errors << "Row - #{row_no} has incomplete data"
            else
              @sport = Sport.find(:first, :conditions => ["name = ?",row[0]])
              @sport = Sport.create(:name => row[0]) if !@sport
              if @sport
                if row[1] != nil
                  @conference = Conference.find(:first, :conditions => ["name = ? and sport_id = ?",row[1],@sport.id])
                  @conference = Conference.create(:name => row[1],:sport_id => @sport.id)  if !@conference
                end
                  conference_id = @conference ? @conference.id : nil
                  if conference_id
			  @team = Team.find(:first, :conditions => ["name = ? and sport_id = ? and conference_id = ?",row[2],@sport.id,conference_id])
		  else
			  @team = Team.find(:first, :conditions => ["name = ? and sport_id = ?",row[2],@sport.id])
		  end

		@team = Team.create(:name => row[2], :sport_id => @sport.id, :conference_id => conference_id) if !@team
                  if @team
                    @event = Event.find(:first,  :conditions => ["name = ? and team_id = ?", row[3],@team.id])
                    begin
                      if @event
                        @event.num_policies = row[5]
                        @event.policy_price = row[4]
                        if row[6].downcase != "yes" 
                          @event.is_active = false
                          deactivate_event(@event.id)
                        end
                        @event.save
                      else
                         @event = Event.create(:team_id => @team.id,
                                   :team_id => @team.id,
                                   :name => row[3],
                                   :num_policies => row[5],
                                   :policy_price => row[4],
                                   :is_active => row[6] == "Yes" ? true : false )
                      end
                    rescue
                      @errors << "Row - #{row_no} : Data is not in the right format"
                    end

                  else
                    @errors << "Row - #{row_no} : Team #{row[3]} does not exist"
                  end
              else
                @errors << "Row - #{row_no} : Sport #{row[1]} does not exist"
              end
            end
          end
          count = count + 1
        end
      end
      flash[:notice] = "Events have been updated" if @errors.size == 0
    end
  end

  def csv_download
    @events = Event.find(:all)
    csv = FasterCSV.generate do |csv|
      csv << ["Sport","Conference", "Team", "Event Name", "Price per Policy", "Number of Policies", "Active?"]
      @events.each do |e|

				if e.team && e.team.conference
					conference = e.team.conference == nil ? "" : e.team.conference.name
    		    end
				if e.team
					csv << [e.team.sport.name,conference,e.team.name,e.name,e.policy_price,e.num_policies,e.is_active ? "Yes" : "No"]
				else
					logger.warn "Event ID didn't have a team! Event ID is: #{e.id}"
				end
      end
    end
    send_data(csv,
      :filename    =>  'events.csv',
      :type            =>  'text/csv',
      :disposition  =>  'inline')
  end
end

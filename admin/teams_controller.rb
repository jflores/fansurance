class Admin::TeamsController < ApplicationController
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
    @team_pages, @teams = paginate :teams, :per_page => 10
  end

  def show
    @team = Team.find(params[:id])
  end

  def new
    @team = Team.new
  end

  def create
    @team = Team.new(params[:team])
    @team.sport_id = params[:sport_id]
    @team.conference_id = params[:conference_id]
    if @team.save
      flash[:notice] = 'Team was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @team = Team.find(params[:id])
  end

  def update
    @team = Team.find(params[:id])
    @team.conference_id = params[:conference_id]
    if @team.update_attributes(params[:team])
      flash[:notice] = 'Team was successfully updated.'
      redirect_to :action => 'show', :id => @team
    else
      render :action => 'edit'
    end
  end

  def destroy
    @team = Team.find(params[:id])
    if @team.has_purchased
      flash[:error] = "Cannot delete as policy has been issued to user"
    else
      @team.destroy
    end
    redirect_to :action => 'list'
  end
  
  def get_conference_list
    if params[:sport_id]
      begin
      @sport = Sport.find(params[:sport_id], :include => :conferences)
      if @sport.conferences.size > 0
        render :partial => 'conference_list', :locals => {:conferences => @sport.conferences}
      else
        render :nothing => true
      end
      rescue
        render :nothing => true
      end
    end
  end
  def edit_team_blurbs
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
          @sport = @conference = @team  = nil
          if count > 0
            row_no = count - 1
            if row[0] == nil && row[1] == nil && row[2] == nil
              @errors << "Row - #{row_no} has incomplete data "
            else
              @sport = Sport.find(:first, :conditions => ["name = ?", row[0]])
              @sport = Sport.create(:name => row[0]) if !@sport
              if @sport
                @conference = Conference.find(:first, :conditions => ["name = ? and sport_id = ?",row[1],@sport.id])
                @conference = Conference.create(:name => row[1],:sport_id => @sport.id)  if !@conference
                if @conference
                  @team = Team.find(:first, :conditions => ["name = ? and sport_id = ? and conference_id = ?", row[2],@sport.id,@conference.id])
                   @team = Team.create(:name => row[2], :sport_id => @sport.id, :conference_id => @conference.id) if !@team
                   if @team 
                     @team.details = row[3]
                     @team.save
                   else
                      @errors << "Row - #{row_no} : Team #{row[2]} cannot be created"
                   end
                else
                  @errors << "Row - #{row_no} : Conference #{row[1]} cannot be created"
                end
              else
                @errors << "Sport #{row[0]} cannot be created"
              end
            end
          end
          count = count + 1
        end
      end
    end
  end
  
  def download_team_blurbs
    @teams = Team.find(:all)
    csv = FasterCSV.generate do |csv|
      csv << ["Sport","Conference", "Team", "Marketing Blurb"]
      @teams.each do |t|
        conference = t.conference == nil ? "" : t.conference.name
        csv << [t.sport.name,conference,t.name,t.details]
      end
    end
    send_data(csv,
      :filename    =>  'teams_marketing_blurb.csv',
      :type            =>  'text/csv',
      :disposition  =>  'inline')
  end
end

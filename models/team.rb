class Team < ActiveRecord::Base
  validates_presence_of :name
  has_many :events
  belongs_to :sport
  belongs_to :conference

  def conference_name
    self.conference ? self.conference.name : "N/A"
  end

  def has_purchased
    if Team.find_by_sql("SELECT t.* FROM teams as t,events as e, inventories as i,policy_for_sales as p WHERE (e.id = i.event_id OR e.id = p.event_id) AND e.team_id=t.id AND t.id = #{self.id}").size > 0
      return true
    else
      return false
    end
  end
end

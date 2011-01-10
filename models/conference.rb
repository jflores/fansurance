class Conference < ActiveRecord::Base
  validates_presence_of :sport_id
  validates_presence_of :name
  has_many :teams
  belongs_to :sport

  def has_purchased
    if Team.find_by_sql("SELECT c.* FROM conferences as c,teams as t,events as e, inventories as i,policy_for_sales as p WHERE (e.id = i.event_id OR e.id = p.event_id) AND e.team_id=t.id AND t.conference_id=c.id and c.id = #{self.id}").size > 0
      return true
    else
      return false
    end
  end
end

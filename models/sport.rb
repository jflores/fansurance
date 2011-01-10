class Sport < ActiveRecord::Base
  validates_presence_of :name
  has_many :teams
  has_many :conferences

  def has_purchased
    if Team.find_by_sql("SELECT s.* FROM sports as s,teams as t,events as e, inventories as i,policy_for_sales as p WHERE (e.id = i.event_id OR e.id = p.event_id) AND e.team_id=t.id AND t.sport_id = s.id and s.id = #{self.id}").size > 0
      return true
    else
      return false
    end
  end
end

class Event < ActiveRecord::Base
  belongs_to :team
  has_many :order_items

  def sport
    self.team.sport
  end
  def has_purchased
    if Event.find_by_sql("SELECT e.* FROM events as e, inventories as i,policy_for_sales as p WHERE (e.id = i.event_id OR e.id = p.event_id) AND e.id=#{self.id}").size > 0
      return true
    else
      return false
    end
  end

  def sport_id
    self.team ? self.team.sport_id : nil
  end

  def conference_name
    self.team ? self.team.conference_name : ""
  end

  def conference
    self.team ? self.team.conference : nil
  end
  def num_policies_in_exchange
    PolicyForSale.find_by_sql("SELECT (IFNULL(SUM(quantity),0) +   0) AS quantity FROM policy_for_sales WHERE 
      event_id = #{self.id}")[0].quantity
  end

  def lowest_exchange_price   
    begin
      PolicyForSale.find(:first, :conditions => ["event_id = ?",self.id], :order => "policy_price").policy_price
    rescue 
      return 0 
    end
  end
  
  def num_policies_for_sale(user_id)
    Inventory.find_by_sql("SELECT (IFNULL(SUM(quantity),0) +   0) AS quantity FROM inventories WHERE 
      event_id = #{self.id} and user_id = #{user_id}")[0].quantity
  end
end

class OrderItem < ActiveRecord::Base
  belongs_to :event
  belongs_to :order
  belongs_to :policy_gift

  attr_reader :policy_held


  def self.for_item(event,quantity,from_fansurance)
    item = self.new
    item.policy_price = event.policy_price
    if from_fansurance
      item.event_id = event.id
    else
      item.event_id = event.event_id
      item.policy_for_sale_id = event.id
    end
    item.quantity = quantity
    item.from_fansurance = from_fansurance
    return item
  end

  def price
    self.policy_price
  end

  def name
    self.event.name
  end

  
end

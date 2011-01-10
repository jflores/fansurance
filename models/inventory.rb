class Inventory < ActiveRecord::Base
  belongs_to :user
  belongs_to :event
  belongs_to :order_item

  def order
    self.order_item.order
  end
end

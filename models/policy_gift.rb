class PolicyGift < ActiveRecord::Base
  has_one :order_item
  belongs_to :receiver, :class_name => "User", :foreign_key => "receiver_id"
  belongs_to :user, :class_name => "User", :foreign_key => "owner_id"
  belongs_to :event
end

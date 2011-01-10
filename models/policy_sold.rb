class PolicySold < ActiveRecord::Base
  belongs_to :user
  belongs_to :event
end

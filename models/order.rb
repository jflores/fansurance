class Order < ActiveRecord::Base
  belongs_to :user
  has_many :order_items

  validates_presence_of :billing_firstname, :message => 'Billing: First Name cannot be empty.'
  validates_presence_of :billing_lastname, :message => 'Billing: Last Name cannot be empty.'
  validates_presence_of :billing_address1, :message => "Billing: Address cannot be empty."
  validates_presence_of :billing_city, :message => "Billing: City cannot be empty."
  validates_presence_of :billing_state, :message => "Billing: State cannot be empty."
  validates_presence_of  :billing_zip, :message => "Billing: Zip cannot be empty."
  validates_presence_of :privacy_agreement, :message => "You need to agree to the privacy agreement."
  
  def billing_name
    self.billing_firstname + ' ' + self.billing_lastname
  end

  def shipping_name
    shipping_same_as_billing ? billing_name : self.shipping_firstname + ' ' + self.shipping_lastname
  end

  def s_address1
    shipping_same_as_billing ? self.billing_address1 : self.shipping_address1
  end
  def s_address2
    shipping_same_as_billing ? self.billing_address2 : self.shipping_address2
  end
  def s_state
    shipping_same_as_billing ? self.billing_state : self.shipping_state
  end
  def s_city
    shipping_same_as_billing ? self.billing_city : self.shipping_city
  end
  def s_zip
    shipping_same_as_billing ? self.billing_zip : self.shipping_zip
  end

  def total_amount
    #self.total_price + self.total_tax + self.total_shipping
    self.total_price  
  end

  def payment_status
    if self.order_status == 'payment_pending'
      return 'Payment is being processed..'
    elsif self.order_status == 'payment_received'
      return 'Payment Received'
    elsif self.order_status == 'payment_cancelled'
      return 'Credit Card Information Invalid. Order Cancelled'
    else
      return ""
    end
  end

  def  validate
    if not shipping_same_as_billing
      #errors.add_on_empty %w( shipping_firstname shipping_lastname shipping_address1
      #shipping_city shipping_state shipping_zip)
      errors.add_on_empty('shipping_firstname', "Shipping: First Name cannot be empty")
      errors.add_on_empty('shipping_lastname', "Shipping: Last Name cannot be empty")
      errors.add_on_empty('shipping_address1', "Shipping: Address  cannot be empty")
      errors.add_on_empty('shipping_city', "Shipping: City cannot be empty")
      errors.add_on_empty('shipping_state', "Shipping: State cannot be empty")
      errors.add_on_empty('shipping_zip', "Shipping: Zip cannot be empty")
    end
  end
end

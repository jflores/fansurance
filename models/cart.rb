class Cart

  attr_accessor :items, :total_price, :total_tax, :total_shipping
  
  def total_amount
    self.total_price + self.total_tax + self.total_shipping 
  end

  def initialize
    empty!
  end

  def add(event,quantity,from_fansurance)
    if from_fansurance
      @prev_item = self.items.select {|i|  i.event_id == event.id && i.from_fansurance } 
      if @prev_item.size > 0
        @prev_item[0].quantity =  @prev_item[0].quantity + quantity
      else
        item = OrderItem.for_item(event,quantity,from_fansurance)
        @items << item
      end
    else
      @prev_item = self.items.select {|i|  i.policy_for_sale_id == event.id}
      if @prev_item.size == 0
        item = OrderItem.for_item(event,quantity,from_fansurance)
        @items << item
      end
    end
    
    @total_price = @total_price + event.policy_price * quantity
  end

  def add_gift(item_index,quantity,note,email,name)
    item = self.items[item_index.to_i]
    quantity = quantity.to_i
    if item.from_fansurance
     gift_item = OrderItem.for_item(item.event,quantity,item.from_fansurance)     
     if item.quantity == quantity
       self.items.delete_at(item_index.to_i)
     else
       self.items[item_index.to_i].quantity = self.items[item_index.to_i].quantity - quantity.to_i
     end
    else
      policy_for_sale = PolicyForSale.find(item.policy_for_sale_id)
      self.items.delete_at(item_index.to_i)
      gift_item = OrderItem.for_item(policy_for_sale,quantity,item.from_fansurance)     
    end
    gift_item.is_gift = true
   
    policy_gift = PolicyGift.new(:event_id => item.event_id, :quantity => quantity,
                                 :receiver_email => email, :note => note,
                                 :receiver_name => name, :policy_price => item.policy_price)
    @receiver = User.find(:first, :conditions => ["email = ?", email])
    policy_gift.receiver_id = @receiver.id if @receiver
    policy_gift.save

    gift_item.policy_gift_id = policy_gift.id
    @items << gift_item
  end
  
  def empty!
    @items = []
    @total_price = 0.0
    @total_tax = 0.0
    @total_shipping = 0.0
  end

end

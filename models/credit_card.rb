class CreditCard < ActiveRecord::Base
# need not check this as order checks for this
#  validates_presence_of :firstname
#  validates_presence_of :lastname, 
  validates_presence_of  :cardType, :message => "CreditCard: Card Type cannot be empty"
  validates_presence_of :cvv2, :message => "CreditCard: verification number should not be empty"
  validates_presence_of :number, :message => "CreditCard: Credit Card number should not be empty"
  def validate
      errors.add('cvv2',"CreditCard: verification number should consist only of numbers") if cvv2 != "" && cvv2 != cvv2.to_i.to_s
  end

  def self.card_types
    { 'Visa'             => 'visa',
      'MasterCard'       => 'mastercard',
      'American Express' => 'amex' 
    }
  end

  def readable_card_type
    (@@card_types ||= self.class.card_types.invert)[card_type]
  end

  def digits
    @digits ||= number.gsub(/[^0-9]/, '')
  end

  def last_digits
    digits.sub(/^([0-9]+)([0-9]{4})$/) { '*' * $1.length + $2 }
  end

  protected
  def number_valid?
    total = 0
    digits.reverse.scan(/(\d)(\d){0,1}/) do |ud,ad|
      (ad.to_i*2).to_s.each {|d| total = total + d.to_i} if ad
      total = total + ud.to_i
    end
    total % 10 != 0
  end
  def number_matches_type?
    digit_length = digits.length
    card_type = cardType.downcase 
    case card_type
      when 'visa'
        [13,16].include?(digit_length) and number[0,1] == "4"
      when 'mastercard'
        digit_length == 16 and ("51" .. "55").include?(number[0,2])
      when 'amex'
        digit_length == 15 and %w(34 37).include?(number[0,2])
      when 'discover'
        digit_length == 16 and number[0,4] == "6011"
    end
  end 
end

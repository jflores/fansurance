require 'digest/sha1'
class User < ActiveRecord::Base
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     :email
  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_presence_of     :email_confirmation,      :if => :email_required?
  validates_confirmation_of :email,                   :if => :email_required?
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :email, :case_sensitive => false
  #validates_presence_of :email_agreement, :message => "^You need to agree to the email agreement."
  validates_presence_of :privacy_agreement, :message => "You need to agree to the privacy agreement."
  validates_presence_of :firstname, :message => "First name can't be blank."
  validates_presence_of :lastname, :message => "Last name can't be blank."
  before_save :encrypt_password
  has_many :gifts_given, :class_name => "PolicyGift" , :foreign_key => "owner_id", :conditions => "transaction_complete = 1 and is_claimed = 0"
  has_many :gifts_received, :class_name => "PolicyGift" , :foreign_key => "receiver_id", :conditions => "transaction_complete = 1 and is_claimed = 0"


  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(email, password)
    u = find_by_email(email) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end
  def forgot_password
     @forgotten_password = true
     self.make_password_reset_code
   end

   def reset_password
     # First update the password_reset_code before setting the 
     # reset_password flag to avoid duplicate email notifications.
     #update_attributes(:password_reset_code => nil)
     @reset_password = true
   end

   def recently_reset_password?
     @reset_password
   end

   def recently_forgot_password?
     @forgotten_password
   end

   def shipping_state_name
     begin
     State.find(:first, :conditions => ["code = ?",self.shipping_state]).name
     rescue
       return "N/A"
     end
   end

   def name
     self.firstname + ' ' + self.lastname
   end

   def policy_inventory
     Inventory.find(:all, :conditions => ["inventories.quantity > 0 AND inventories.user_id = #{self.id}
                                                    AND inventories.is_active = 1"], :include => :event)
   end

   def policy_for_sale
     PolicyForSale.find(:all,:conditions => ["policy_for_sales.quantity > 0 AND policy_for_sales.user_id = #{self.id}
                                                        AND policy_for_sales.is_active = 1"], :include => :event)
   end

   def policy_sold
      PolicySold.find(:all, :conditions => ["user_id = #{self.id}"])
   end

   def inactive_policies
     Inventory.find(:all, :conditions => ["quantity > 0 AND user_id = #{self.id}
                                                                    AND is_active = 0"]) +
     PolicyForSale.find(:all,:conditions => ["policy_for_sales.quantity > 0 AND policy_for_sales.user_id = #{self.id}
                                                        AND policy_for_sales.is_active = 0"])
   end

   def gifts_claimed
     PolicyGift.find(:all, :conditions => ["owner_id = #{self.id} AND transaction_complete = 1 and is_claimed = 1 "])
   end

   def last_logged_in_on
     self.last_logged_in ? self.last_logged_in.strftime("%m-%d-%Y") : "Not logged in ever"
   end
   protected

     def make_password_reset_code
       self.password_reset_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
     end

    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      crypted_password.blank? || !password.blank?
    end

    def email_required?
      !email.blank?
    end
end

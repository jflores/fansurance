class UserNotifier < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    = 'Welcome to Fansurance.com!'
    @body[:url]  = "http://www.fansurance.com"
  end
  
  def activation(user)
    setup_email(user)
    @subject    = 'Your account has been activated.'
    @body[:url]  = "http://YOURSITE/"
  end

  def forgot_password(user)
    setup_email(user)
    @subject    = 'You requested a password change.'
    @body[:url]  = "http://www.fansurance.com/account/reset_password/#{user.password_reset_code}" 
  end

  def reset_password(user)
    setup_email(user)
    @subject    = 'Your password has been reset.'
  end

  def claim_gift(email,is_user=false)
    @recipients  = email
    @from        = %("The Fansurance Team" <support@fansurance.com>)
    @subject = "Someone purchased you a Fansurance policy!"
    @sent_on     = Time.now
    @body[:is_user] = is_user
    @body[:url]  = "http://www.fansurance.com/account/signup" 
    @body[:login_url]  = "http://www.fansurance.com/account/login" 
  end

  def share_team(email,name,name_friend,email_friend,note,team_id)
    @recipients = email_friend
    @from        = %("The Fansurance Team" <support@fansurance.com>)
    @subject  = "#{name} wants you to check out Fansurance.com!"
    @sent_on     = Time.now
    @body[:url]  = "http://www.fansurance.com/site/events?team_id=#{team_id}"
    @body[:name] = name
    @body[:email] = email
    @body[:friend_name] = name_friend
    @body[:note] = note
  end
    

  protected
  def setup_email(user)
    @recipients  = "#{user.email}"
    @from        = %("The Fansurance Team" <support@fansurance.com>) 
    @subject     = "Fansurance.com"
    @sent_on     = Time.now
    @body[:user] = user
  end
end

class UserObserver < ActiveRecord::Observer
  def after_create(user)
    UserNotifier.deliver_signup_notification(user)
  end
=begin

  def after_save(user)
    UserNotifier.deliver_activation(user) if user.recently_activated?
  end
=end

  def after_save(user)
    UserNotifier.deliver_forgot_password(user) if user.recently_forgot_password?
    UserNotifier.deliver_reset_password(user) if user.recently_reset_password?
  end
end

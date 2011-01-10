class Admin::UsersController < ApplicationController
  before_filter :admin_required
  layout 'admin'

  def index
    browse
    render :action => 'browse'
  end

  def browse
    @users = User.find(:all, :order => 'firstname')
  end

  def details
    @user = User.find(params[:id])
    @inventory = @user.policy_inventory
  end

  def view_policy
    @order_item = OrderItem.find(params[:id])
    @event = @order_item.event
  end
end

class Admin::TransactionsController < ApplicationController
  before_filter :admin_required
  layout 'admin'

  def index
    if request.post?
      if params[:start_time] != "" and params[:end_time] != ""
        @start_time = params[:start_time]
        @end_time = params[:end_time]
      else
        flash[:error] = "Choose both start and end dates"
      end
    else
      if params[:num_days]
        num_days = params[:num_days].to_i
      else
        num_days = 7
      end
      @start_time = (Time.now - num_days.days).strftime('%Y-%m-%d')
      @end_time = Time.now.strftime('%Y-%m-%d')
    end
    @transactions = OrderItem.find_by_sql("SELECT oi.*,y.event_name as event_name, y.team_name AS team_name, y.sport_name AS sport_name
            FROM order_items as oi, orders as o, (SELECT e.id AS event_id, e.name AS event_name, x.team_name AS team_name, x.sport_name AS sport_name FROM `events` e INNER JOIN (SELECT t.id AS team_id, t.name AS team_name, s.name AS sport_name FROM teams t INNER JOIN sports s ON t.sport_id = s.id) x ON e.team_id = x.team_id) y
            WHERE oi.event_id = y.event_id AND oi.order_id = o.id
            AND o.created_at >= '#{@start_time}' and o.created_at <= DATE_ADD('#{@end_time}', INTERVAL 1 DAY)")
  end

end

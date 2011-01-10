# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def policies_in_exchange(event)
    if event.num_policies_in_exchange > 0
       return  pluralize(event.num_policies_in_exchange,"Policy", "Policies") + " from $#{event.lowest_exchange_price}"
    else
      return "No Policies available from exchange."
    end
  end
  
  def menu 
      ret =<<EOF
<ul>
  <li class="home first"><a href="/">home</a></li>
  <li class="about"><a href="/site/about_us">about us</a></li>			
  <li class="contact"><a href="/site/contact_us">contact us</a></li>
  <li class="guarantee"><a href="/site/the_gurantee">the guarantee</a></li>			
  <li class="faq"><a href="/site/faq">faq</a></li>
  <li class="legal"><a href="/site/legal">legal stuff</a></li>			
  <li class="news last"><a href="/site/news">news</a></li>
</ul>
EOF
    return ret
  end
  
  def get_cart 
    return session[:cart] ||= Cart.new
  end

  def sports_with_policies
  
	pforsale = PolicyForSale.count_by_sql "SELECT COUNT(*) from policy_for_sales"
  
	if pforsale > 0
	    Sport.find_by_sql("SELECT DISTINCT s.* FROM sports AS s,  events as e, policy_for_sales as p,teams as t
	       WHERE ((e.num_policies > 0 OR (p.event_id = e.id and p.quantity > 0)) AND e.team_id = t.id ) AND t.sport_id = s.id")
	else
	    Sport.find_by_sql("SELECT DISTINCT s.* FROM sports AS s,  events as e, teams as t
	       WHERE e.num_policies > 0 AND e.team_id = t.id AND t.sport_id = s.id")	
	end
  end
end

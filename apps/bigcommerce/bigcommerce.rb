module Bigcommerce
  module EventHandler
    # Handle 'ticket.created' event
    def ticket_created
      ticket = payload.ticket
      requester = ticket.requester

      begin
        api = connect_to_bigcommerce
        
        if api
          order = get_orders(api)
          html = order_info_html(order)
        else
          return [500, "Ticket not sent. Unable to connect to Bigcommerce"]
        end

      rescue Exception => e
        puts "#{e.message}\n#{e.backtrace}"
        [500, e.message]
      end

      comment_on_ticket(ticket, html)
      [200, "Ticket sent to Bigcommerce"]
    end
  end
end

module Bigcommerce
  module ActionHandler
    def button
     # Handle Action here
     [200, "Success"]
    end
  end
end

module Bigcommerce
  class Base < SupportBeeApp::Base
    string :username, :required => true, :label => 'Enter User Name'
    string :api_token, :required => true, :hint => 'Enter Api Token'
    string :shop_url, :required => true, :label => 'Enter Shop URL'

    def connect_to_bigcommerce
      api = Bigcommerce::Api.new({
      :store_url => settings.shop_url,
      :username  => settings.username,
      :api_key   => settings.api_token
      })
    end

    def get_orders(api)
      orders = api.get_orders.last
    end

    def order_info_html(order)
      html = ""
      html << "Order Details"
      html << "<br/>Status:"
      html << "<br/>#{order['status']}"
      html << "<br/>Subtotal:"
      html << "<br/>#{order['subtotal_inc_tax']}"
      html << "<br/>Total:"
      html << "<br/>#{order['total_inc_tax']}"
      html << "<br/>Date Created:"
      html << "<br/>#{order['date_created']}"
      html << "<br/>" 
      html << "<br/>"
      html << "Order Link"
      html << "<br/>"
      html << order_info_link(order)
      html
    end

    def order_info_link(order)
      url = settings.shop_url.split("/api").first
      "<a href='#{url}/admin/index.php?ToDo=viewOrder&orderId=#{order['id']}'>View Order Info</a>"
    end
  
    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end
  end
end


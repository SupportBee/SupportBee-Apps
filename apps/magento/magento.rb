module Magento
  module EventHandler                      
    def ticket_created
      ticket = payload.ticket
      requester = ticket.requester

      begin
        client = get_client
        session_id = get_session_id(client)

        if session_id
	  order = get_order(client, session_id, requester)
          html = order_info_html(order, client, session_id)
          send_new_comment(client, session_id, ticket, order)
        else
          return [500, "Ticket not sent. Unable to create new session"]
        end

      rescue Exception => e
        puts "#{e.message}\n#{e.backtrace}"
        [500, e.message]
      end
        
      comment_on_ticket(ticket, html)
      [200, "Ticket sent to Magento"]
    end
  end
end

module Magento
  module ActionHandler
    def button
     # Handle Action here
     [200, "Success"]
    end
  end
end

module Magento
  class Base < SupportBeeApp::Base
    string :subdomain, :required => true, :label => 'Enter Subdomain'
    string :username, :required => true, :label => 'Enter API User Name'
    string :api_key, :required => true, :label => 'Capsule Auth Token'
 
    # White list settings for logging
    # white_list :name, :username
    
    def get_client
      client = Savon.client(wsdl: "http://#{settings.subdomain}.gostorego.com/api/v2_soap?wsdl=1", ssl_ca_cert_file: "./config/cacert.pem")
    end

    def get_session_id(client)
      username = settings.username.to_s
      api_key  = settings.api_key.to_s
      response = client.call(:login){message(username: username, apiKey: api_key)}
      session_id = response.body[:login_response][:login_return]
    end

    def get_order(client, session_id, requester)
        result = client.call(:sales_order_list){message(:sessionId => session_id, :resourcePath => 'sales_order.list')}
        order_list = result.body[:sales_order_list_response][:result][:item] if result
        order = order_list.select{|order| order[:customer_email] == requester.email}.first if order_list
    end
   
    def send_new_comment(client, session_id, ticket, order)
      client.call(:sales_order_add_comment){message(:sessionId => session_id, :orderIncrementId => order[:increment_id], :resourcePath => 'sales_order.addComment', :comment => generate_comment(ticket), :status => 'pending')}
    end
 
    def generate_comment(ticket)
      "https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"
    end

    def order_info_html(order, client, session_id)
      order_items = get_ordered_items(order, client, session_id)
      html = ""
      html = "Ordered Items:"
      html << "<br/>"
      order_items.select{|p| html << p[:name] + "<br/>"} if order_items
      html << order_info_link(order)
      html
    end

    def get_ordered_items(order, client, session_id)
      result = client.call(:sales_order_info){message(:sessionId => session_id, :orderIncrementId => order[:increment_id], :resourcePath => 'sales_order.info')}
      order_items = result.body[:sales_order_info_response][:result][:items][:item] if result
    end

    def order_info_link(order)
      "<a href= 'https://#{settings.subdomain}.gostorego.com/index.php/admin/sales_order/view/order_id/#{order[:order_id]}'>View Order Info</a>"
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end
  end
end


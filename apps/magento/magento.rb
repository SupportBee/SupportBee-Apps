module Magento
  module EventHandler
    def ticket_created
      ticket = payload.ticket
      requester = ticket.requester

      client = get_client
      response = perform_client_login(client)
      session_id = get_session_id(response)
      if session_id
        orders = get_order(client, session_id, requester)
        html = order_info_html(orders, client, session_id)
        send_new_comment(client, session_id, ticket, orders)
      else
        return response
      end

      comment_on_ticket(ticket, html)
    end
  end
end

module Magento
  class Base < SupportBeeApp::Base
    string :subdomain, :required => true, :label => 'Enter Subdomain', :hint => 'If your Magento URL is "https://something.gostorego.com" then your Subdomain value is "something"'
    string :username, :required => true, :label => 'Enter API User Name', :hint => 'See how to create an api user and key in "http://www.magentocommerce.com/wiki/modules_reference/english/mage_adminhtml/api_user/index"'
    string :api_key, :required => true, :label => 'Enter API Key'

    def validate
      begin
        test_api_request
      rescue Savon::SOAPFault => e
        report_exception(e)

        show_error_notification "We could not reach Magento. Please check the configuration and try again"
        return false
      end

      true
    end

    private

    def test_api_request
      get_client.call(:login) { message(username: username, apiKey: api_key) }
    end

    def get_client
      client = Savon.client(wsdl: "http://#{settings.subdomain}.gostorego.com/api/v2_soap?wsdl=1", ssl_ca_cert_file: "./config/cacert.pem")
    end

    def perform_client_login(client)
      username = settings.username.to_s
      api_key  = settings.api_key.to_s

      response = client.call(:login) { message(username: username, apiKey: api_key) }
    end

    def get_session_id(response)
      session_id = response.body[:login_response][:login_return] if response
    end

    def get_order(client, session_id, requester)
      result = client.call(:sales_order_list){message(:sessionId => session_id, :resourcePath => 'sales_order.list')}
      order_list = result.body[:sales_order_list_response][:result][:item] if result
      orders = order_list.select{|order| order[:customer_email] == requester.email} if order_list
    end

    def send_new_comment(client, session_id, ticket, orders)
      order = orders.last
      client.call(:sales_order_add_comment){message(:sessionId => session_id, :orderIncrementId => order[:increment_id], :resourcePath => 'sales_order.addComment', :comment => generate_comment(ticket), :status => 'pending')}
    end

    def generate_comment(ticket)
      "[Support Ticket] https://#{auth.subdomain}.supportbee.com/tickets/#{ticket.id}"
    end

    def order_info_html(orders, client, session_id)
      order_items = get_ordered_items(orders, client, session_id)
      order = orders.last
      items_html = order_items_html(order_items)
      date = DateTime.parse(order[:created_at])
      formatted_date = date.strftime('%a %b %d %H:%M:%S')
      html = ""
      html << "<h3>Order Details<p>"
      html << "<p>Order Count: #{orders.count}"
      html << "<p>Ordered Items:"
      html << items_html
      html << "<p><p><table>"
      html << "<tr><th><h5>Status:"
      html << "</th><th><h5>Subtotal:"
      html << "</th><th><h5>Total:"
      html << "</th><th><h5>Date Created:"
      html << "</th></tr><tr><td>#{order[:status]}"
      html << "</td><td>#{order[:subtotal].to_f}"
      html << "</td><td>#{order[:grand_total].to_f}"
      html << "</td><td>#{formatted_date}"
      html << "</td></tr>"
      html << "</table>"
      html << "<p>"
      html << ">>" + order_info_link(order)
      html
    end

    def get_ordered_items(orders, client, session_id)
      order = orders.last
      result = client.call(:sales_order_info){message(:sessionId => session_id, :orderIncrementId => order[:increment_id], :resourcePath => 'sales_order.info')}
      order_items = result.body[:sales_order_info_response][:result][:items][:item] if result
    end

    def order_info_link(order)
      "<a href= 'https://#{settings.subdomain}.gostorego.com/index.php/admin/sales_order/view/order_id/#{order[:order_id]}'>View Order Info</a>"
    end

    def order_items_html(order_items)
      html = ""
      if order_items.kind_of?(Array)
        order_items.select{|item| html << "<br/><h5 style=\"font-weight:normal\">#{item[:name]}"}
      else
        html << "<br/><h5 style=\"font-weight:normal\">#{order_items[:name]}" if order_items
      end
      return html
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end
  end
end

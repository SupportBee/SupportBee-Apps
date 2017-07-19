module Bigcommerce
  module EventHandler
    def ticket_created
      ticket = payload.ticket
      requester = ticket.requester
      http.basic_auth(settings.username, settings.api_token)

      api = connect_to_bigcommerce

      email = ticket.requester.email

      customers = get_customers(api, email)
      return if customers.empty?

      customer = customers.first
      orders = get_orders(api, customer)
      return if orders.empty?

      order_html = order_info_html(api, orders)
      sent_note_to_customer(api, orders)
      ticket.comment(:html => order_html)

      show_success_notification "Ticket sent to Bigcommerce"
    end
  end
end

module Bigcommerce
  class Base < SupportBeeApp::Base
    string :username, :required => true, :label => 'Enter User Name', :hint => 'See how to create an api user and get the token in "https://support.bigcommerce.com/questions/1560/How+do+I+enable+the+API+for+my+store%3F"'
    string :api_token, :required => true, :label => 'Enter Api Token'
    string :shop_url, :required => true, :label => 'API URL',  :hint => 'You should see this when enabling API access for this user. Example "https://store-bwvr466.mybigcommerce.com/api/v2/"'

    white_list :subdomain

    def connect_to_bigcommerce
      api = Bigcommerce::Api.new({
      :store_url => settings.shop_url,
      :username  => settings.username,
      :api_key   => settings.api_token
      })
    end

    def get_customers(api, email)
      begin
        api.get_customers :email => email
      rescue
        # Somehow the API throws
        # Failed to parse Bigcommerce response: A JSON text must at least contain two octets!
        # if a record cannot be found!
        []
      end
    end

    def get_orders(api, customer)
      orders = api.get_orders :customer_id => customer['id']
    end

    def sent_note_to_customer(api, orders)
      order = orders.last
      notes = "#{generate_note}\n#{order['staff_notes']}"
      api.connection.put "/orders/#{order['id']}", staff_notes: notes
    end

    def generate_note
      "[SupportBee] #{payload.ticket.subject} - https://#{auth.subdomain}.supportbee.com/tickets/#{payload.ticket.id}"
    end

    def order_info_html(api, orders)
      store_id = api.connection.get("/store")['id']
      order = orders.last
      order_items = get_ordered_items(order)
      items_html = order_items_html(order_items)
      date = DateTime.parse(order['date_created'])
      formatted_date = date.strftime('%a %b %d %H:%M:%S')
      html = ""
      html << "<h3>Order Details"
      html << "<p>Order Count: #{orders.count}"
      html << "<p>Last Order Details:"
      html << items_html
      html << "<p><p><table>"
      html << "<tr><th><h5>Status:"
      html << "</th><th><h5>Subtotal:"
      html << "</th><th><h5>Total:"
      html << "</th><th><h5>Date Created:"
      html << "</th></tr><tr><td>#{order['status']}"
      html << "</td><td>#{order['subtotal_inc_tax'].to_f}"
      html << "</td><td>#{order['total_inc_tax'].to_f}"
      html << "</td><td>#{formatted_date}"
      html << "</td></tr>"
      html << "</table>"
      html << order_info_link(order, store_id) + " &raquo;"
      html
    end

    def order_info_link(order, store_id)
      "<a href='https://store-#{store_id}.mybigcommerce.com/admin/index.php?ToDo=viewOrder&orderId=#{order['id']}'>View Order Info</a>"
    end

    def get_ordered_items(order)
      url = order['products']['url']
      response = http.get "#{url}" do |req|
        req.params['Accept'] = "application/json"
      end
      order_items = response.body if response
    end

    def order_items_html(order_items)
      html = ""
      if order_items.kind_of?(Array)
        order_items.select{|item| html << "<br/><h5 style=\"font-weight:normal\">#{item['name']}"}
      else
        html << "<br/><h5 style=\"font-weight:normal\">#{order_items['name']}" if order_items
      end
      return html
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end
  end
end

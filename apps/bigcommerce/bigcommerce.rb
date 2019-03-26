module Bigcommerce
  module EventHandler
    def ticket_created
      customers = get_customers_whose_email_is(ticket.requester.email)
      return if customers.empty?
      customer = customers.first

      orders = get_customer_orders(customer)
      return if orders.empty?
      most_recent_order = orders.last

      order_html = order_info_html(orders)
      sent_note_to_customer(most_recent_order)
      ticket.comment(:html => order_html)
    end
  end
end

module Bigcommerce
  class Base < SupportBeeApp::Base
    string :username, :required => true, :label => 'Enter User Name', :hint => 'See how to create an api user and get the token in "https://support.bigcommerce.com/questions/1560/How+do+I+enable+the+API+for+my+store%3F"'
    string :api_token, :required => true, :label => 'Enter Api Token'
    string :shop_url, :required => true, :label => 'API URL',  :hint => 'You should see this when enabling API access for this user. Example "https://store-bwvr466.mybigcommerce.com/api/v2/"'

    white_list :subdomain

    def api
      @api ||= Bigcommerce::Api.new(
        :store_url => settings.shop_url,
        :username  => settings.username,
        :api_key   => settings.api_token
      )
    end

    def get_customers_whose_email_is(email)
      begin
        api.get_customers(:email => email)
      rescue
        # Somehow the API throws
        # Failed to parse Bigcommerce response: A JSON text must at least contain two octets!
        # if a record cannot be found!
        []
      end
    end

    def get_customer_orders(customer)
      orders = api.get_orders(:customer_id => customer['id'])
    end

    def sent_note_to_customer(most_recent_order)
      notes = "#{generate_note}\n#{order['staff_notes']}"
      api.connection.put "/orders/#{order['id']}", staff_notes: notes
    end

    def generate_note
      "[SupportBee] #{ticket.subject} - #{ticket_url}"
    end

    def order_info_html(orders)
      store_id = api.connection.get("/store")['id']
      order = orders.last
      order_items = get_order_items(order)
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

    def order_info_link(order)
      order_url = order_url(order)
      "<a href='#{order_url}'>View Order Info</a>"
    end

    def order_url(order)
      store_url = api.connection.get("/store")["secure_url"]
      order_id = order['id']
      "https://#{store_url}/admin/index.php?ToDo=viewOrder&orderId=#{order_id}"
    end

    def get_order_items(order)
      url = order['products']['url']
      http.basic_auth(settings.username, settings.api_token)
      response = http.get("#{url}") do |req|
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

    def ticket_url
      "https://#{company_subdomain}.supportbee.com/tickets/#{ticket.id}""
    end

    def ticket
      payload.ticket
    end

    def company_subdomain
      auth.subdomain
    end
  end
end

module Trello
  module ActionHandler
    def button
      ticket = payload.tickets.first
      card = create_card(payload.overlay.title, payload.overlay.description)
      html = card_info_html(ticket, card)
      
      comment_on_ticket(ticket, html)
      [200, "Success"]
    end

    def boards
      [200, fetch_boards]
    end

    def lists
      [200, fetch_lists]
    end
  end
end

module Trello
  class Base < SupportBeeApp::Base
    oauth :trello, :oauth_options => {:app_name => "SupportBee", :expiration => :never, :scope => "read,write"}
    string :board, :required => true, :label => 'Name of Trello board'
    string :list, :required => true , :label => 'Name of Trello list'

    def create_card(card_title, description)
      trello_client.create(:card, 'name' => card_title, 'desc' => description, 'idList' => list_id)
    end

    def fetch_boards
      trello_client.get("/members/#{me.username}/boards")
    end

    def fetch_lists
      trello_client.get("/boards/#{payload.overlay.board}/lists")
    end

    def me
      trello_client.find('members', 'me')
    end

    def trello_client
     @client ||= Trello::Client.new(
        :consumer_key => OMNIAUTH_CONFIG['trello']['key'],
        :consumer_secret => OMNIAUTH_CONFIG['trello']['secret'],
        :oauth_token => settings.oauth_token,
        :oauth_token_secret => settings.oauth_secret
      )
    end

    def card_info_html(ticket, card)
      "Trello Card Created!\n <a href='#{card.url}'>#{ticket.subject}</a>"      
    end

    def comment_on_ticket(ticket, html)
      ticket.comment(:html => html)
    end
  end
end


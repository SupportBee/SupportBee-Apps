
module Trello
  module ActionHandler
    def button
      create_card(payload.overlay.title, payload.overlay.description)
     [200, "Success"]
    end
  end
end

module Trello
  class Base < SupportBeeApp::Base
    oauth :trello, :oauth_options => {:app_name => "SupportBee", :expiration => :never, :scope => "read,write"}
    string :board, :required => true, :hint => 'Name of Trello board'
    string :list, :required => true , :hint => 'Name of Trello list'

    def create_card(card_title, description)
      @client = setup_client
      board_id = find_board
      return false unless board_id
      list_id = find_or_create_list(board_id)
      @client.create(:card, 'name' => cart_title, 'desc' => description, 'idList' => list_id)
    end

    def setup_client
     Trello::Client.new(
        :consumer_key => OMNIAUTH_CONFIG['trello']['key'],
        :consumer_secret => OMNIAUTH_CONFIG['trello']['secret'],
        :oauth_token => settings.oauth_token,
        :oauth_token_secret => settings.oauth_secret
      )
    end

    def find_board
      board = (JSON.parse @client.get('/members/me/boards')).select{|b| b['name'] == settings.board}.first
      board["id"]
    end

    def find_or_create_list(board_id)
      list = (JSON.parse @client.get("/boards/#{board_id}/lists")).select{|b| b.name == settings.list}.first
      list = @client.create(:list, 'name' => settings.list, 'idBoard' => board_id) unless list
      list['id']
    end

  end
end


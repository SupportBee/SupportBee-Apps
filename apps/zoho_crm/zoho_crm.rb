module ZohoCrm
  module EventHandler
    def ticket_created
    	setup_zoho
			ticket = payload.ticket
      requester = ticket.requester 
      person = find_person requester
      ticket.comment(:html => person_info_html(person)) if person
    end
  end
end

module ZohoCrm
  class Base < SupportBeeApp::Base
    
    string :api_token, :required => true, :label => 'ZohoCRM Auth Token'
    
    def setup_zoho
    	@params = { :authtoken		=> settings.api_token,
    							:scope				=> 'crmapi',
    							:newFormat		=> 1
    	}
    end
    
    def find_person(requester)
			zoho_response = http_get(leads_uri, @params)
			zoho_response = JSON.parse(zoho_response.body)
			people = convert_zoho_response_to_array zoho_response
			person = find_by_email requester.email, people
			person ? person : nil
    end
    
    def leads_uri
    	URI('https://crm.zoho.com/crm/private/json/Leads/getMyRecords')
    end
    
    def convert_zoho_response_object_to_hash(json_object)
			obj = {}
			json_object.each do |pair|
				obj[pair["val"].downcase.gsub(/\s+/, "_").to_sym] = pair["content"]
			end
			obj
		end
		
		def convert_zoho_response_to_array(response)
			result = []
			response = response["response"]["result"]["Leads"]["row"]
			response.each {|res| result << convert_zoho_response_object_to_hash(res["FL"]) }
			puts result.to_s
			result
		end

		def find_by_email(email, people)
			person = nil
			people.each do |p|
				person = p if p[:email] == email
			end
			person
		end
		
    def person_info_html(person)
      html = ""
      html << "<b> #{person[:salutation]} #{person[:first_name]} #{person[:last_name]} </b><br/>" 
      html << "#{person[:title]} " if person[:title]
      html << "#{person[:company]}" if person[:company]
      html << "<br/>"
#      html << person_link(person)
      html
    end


  end
end


module Basecamp
  module ActionHandler
    def button
      http.basic_auth(settings.email_id, settings.password)

      begin
        create_message(payload.overlay.title, payload.overlay.description)
      rescue Exception => e
        return [500, e.message]
      end

      [200, "Ticket sent to Basecamp"]

    end
  end
end

module Basecamp
  class Base < SupportBeeApp::Base
    string :email_id, :required => true, :label => 'Enter Email ID'
    password :password, :required => true, :label => 'Enter Password'
    string :account_id, :required => true, :label => 'Enter Account ID'
    string :project_id, :required => true, :label => 'Enter Project ID'
   # string :todolist_id, :required => true, :label => 'Enter Todolist ID'
    
   # def create_todo
   #   response = http.post "https://basecamp.com/2213136/api/v1/projects/2479153/todolists/6336257/todos.json" do |req|
   #     req.headers['Content-Type'] = 'application/json'
   #     req.body = {content:'this is a test to create a new todo'}.to_json
   #   end
   # end
  
    def create_message(subject, content)
      response = http.post "https://basecamp.com/2213136/api/v1/projects/2479153/messages.json" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {subject:subject, content:content}.to_json 
      end
    end

  end
end


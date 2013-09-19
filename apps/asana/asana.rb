module Asana 
  module ActionHandler
    def button
      http.basic_auth(settings.token, "")
      begin
        response = create_task(payload.overlay.title, payload.overlay.notes)
        return [500, response.body['errors'].first['message']] if response.body['errors'] and not(response.body['errors'].empty?)
      rescue Exception => e
        puts e.message
        puts e.backtrace
        return [500, e.message]
      end

      [200, "Ticket sent to Asana"]

    end
  end
end

module Asana
  class WorkspaceNotFound < ::StandardError
    def message
      "Cannot find Workspace"
    end
  end

  class ProjectNotFound < ::StandardError
    def message
      "Cannot find Project"
    end
  end

  class Unauthorized < ::StandardError
    def message
      "Unauthorized. Please check if you have provided the right token in the app's settings page."
    end
  end

  class Base < SupportBeeApp::Base
    string :workspace, :required => true, :label => 'Workspace Name'
    string :project, :required => true, :label => 'Project Name'
    string :token, :required => true, :label => 'Token'

    private

    def create_task(task_name, notes)
      workspace_id = fetch_workspace
      task_id = add_task_to_workspace(workspace_id, task_name, notes)
      project_id = fetch_project(workspace_id)
      add_project_to_task(task_id, project_id)    
    end

    def add_task_to_workspace(workspace_id, task_name, notes)
      response = http_post "https://app.asana.com/api/1.0/tasks" do |req|
        req.headers['Content-Type'] = 'application/json'
        req.body = {:data => {:workspace => workspace_id, :name => task_name, :notes => notes, :assignee => 'me'}}.to_json
      end
      response.body['data']['id']
    end

    def fetch_workspace
      response = http_get "https://app.asana.com/api/1.0/workspaces"
      raise Unauthorized if response.status == 401
      workspace = response.body['data'].select {|workspace| workspace['name'] == settings.workspace.strip}
      raise WorkspaceNotFound if workspace.empty?
      workspace.first['id']
    end

    def fetch_project(workspace_id)
      response = http_get "https://app.asana.com/api/1.0/workspaces/#{workspace_id}/projects"
      project = response.body['data'].select {|project| project['name'] == settings.project.strip}
      raise ProjectNotFound if project.empty?
      project.first['id']
    end

    def add_project_to_task(task_id, project_id)
      http_post "https://app.asana.com/api/1.0/tasks/#{task_id}/addProject" do |req|
        req.params[:project] = project_id
      end
    end
  end
end

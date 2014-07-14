Jira = {}
Jira.Views = {}

project_option_tag = (item) ->
  "<option value='#{item.get('key')}'>#{item.get('name')}</option>"

users_option_tag = (item) ->
  "<option value='#{item.get('name')}'>#{item.get('displayName')}</option>"

issue_type_option_tag = (item) ->
  "<option value='#{item.get('id')}'>#{item.get('name')}</option>"

Jira.Views.Overlay = SB.Apps.BaseView.extend(

  events: {
    'change [name="project_select"]': 'project_changed'
    'click a.submit': 'submit_form'
  }

  initialize: ->
    SB.Apps.BaseView.prototype.initialize.call(this)

    _.bindAll this, 'render_projects', 'render_one_project',
                    'render_issue_types', 'render_one_issue_type',
                    'render_users', 'render_one_user', 'project_changed'

    @setup_selectors()
    @setup_users()
    @setup_issue_type()
    @populate_projects()

  setup_selectors: ->
    @projects_selector = @$("[name='projects_select']")
    @users_selector = @$("[name='users_select']")
    @issue_type_selector = @$("[name='issue_type_select']")
    @title_el = @$(".title")
    @description_el = @$(".description")

  populate_projects: ->
    @projects = new SB.Apps.BaseCollection([], app: @app, endpoint: 'projects')
    @projects.on 'reset', @render_projects
    @projects.fetch()

  render_projects: ->
    @projects.each @render_one_project
    @load_users()

  render_one_project: (project) ->
    @projects_selector.append project_option_tag(project)

  project_changed: ->
    @reset_users()
    @load_users()

  reset_users: ->
    @users_selector.find('option').remove().end().append('<option value="none">No Assignee(changed)</option>').val("none")

  load_users: ->
    project = @projects_selector.val()
    @users.request_params = {projects_select: project}
    @users.fetch()

  setup_users: ->
    @users = new SB.Apps.BaseCollection([], endpoint: 'users', app: @app)
    @users.on 'reset', @render_users

  render_users: ->
    @users.each @render_one_user

  render_one_user: (user) ->
    @users_selector.append users_option_tag(user)

  setup_issue_type: ->
    @issue_types = new SB.Apps.BaseCollection([], endpoint: 'issue_types', app: @app)
    @issue_types.on 'reset', @render_issue_types
    @issue_types.fetch()

  render_issue_types: ->
    @issue_types.each @render_one_issue_type

  render_one_issue_type: (issue_type) ->
    @issue_type_selector.append issue_type_option_tag(issue_type)

  submit_form: ->
    @post 'button', @$('form').toJSON()

)

return Jira

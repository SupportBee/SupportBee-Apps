Jira = {}
Jira.Views = {}

project_option_tag = (item) ->
  "<option value='#{item.get('key')}'>#{item.get('name')}</option>"

users_option_tag = (item) ->
  "<option value='#{item.get('name')}'>#{item.get('displayName')}</option>"

Jira.Views.Overlay = SB.Apps.BaseView.extend(

  events: {
    'change [name="project_select"]': 'project_changed'
    'click a.submit': 'submit_form'
  }

  initialize: ->
    SB.Apps.BaseView.prototype.initialize.call(this)

    _.bindAll this, 'render_projects', 'render_one_project',
                    'render_users', 'render_one_user', 'project_changed'

    @setup_selectors()
    @setup_users()
    @populate_projects()

  setup_selectors: ->
    @projects_selector = @$("[name='projects_select']")
    @users_selector = @$("[name='users_select']")
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
    @users_selector.find('option').remove().end().append('<option value="none"></option>').val("none")

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
    @users_selector.appen users_option_tag(user)

  submit_form: ->
    @post 'button', @$('form').toJSON()

)

return Jira

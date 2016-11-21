Insightly = {}
Insightly.Views = {}

option_tag = (item) ->
  "<option value='#{item.get('PROJECT_ID')}'>#{item.get('PROJECT_NAME')}</option>"

users_option_tag = (item) ->
  "<option value='#{item.get('USER_ID')}'>#{item.get('FIRST_NAME')} #{item.get('LAST_NAME')}</option>"

Insightly.Views.Overlay = SB.Apps.BaseView.extend
  events: {
    'click a.submit': 'submit_form'
  }

  initialize: ->
    SB.Apps.BaseView.prototype.initialize.call(this)

    _.bindAll this, 'render_projects', 'render_one_project', 'render_users', 'render_one_user'

    @setup_selectors()
    @populate_projects()
    @populate_users()

  setup_selectors: ->
    @projects_selector = @$("[name='projects_select']")
    @responsible_selector = @$("[name='responsible_select']")
    @owner_selector = @$("[name='owner_select']")
    @title_el = @$(".title")
    @description_el = @$(".description")

  populate_projects: ->
    @projects = new SB.Apps.BaseCollection([], app: @app, endpoint: 'projects')
    @projects.on 'reset', @render_projects
    @projects.fetch()

  render_projects: ->
    @projects_selector.append "<option value='none'>None</option>"
    @projects.each @render_one_project

  render_one_project: (project) ->
    @projects_selector.append option_tag(project)

  populate_users: ->
    @users = new SB.Apps.BaseCollection([], app: @app, endpoint: 'users')
    @users.on 'reset', @render_users
    @users.fetch()

  render_users: ->
    @users.each @render_one_user

  render_one_user: (user) ->
    @responsible_selector.append users_option_tag(user)
    @owner_selector.append users_option_tag(user)

  submit_form: ->
    @post 'button', @$('form').toJSON()

return Insightly

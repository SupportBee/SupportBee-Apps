Insightly = {}
Insightly.Views = {}

option_tag = (item) ->
  "<option value='#{item.get('PROJECT_ID')}'>#{item.get('PROJECT_NAME')} (#{item.get('STATUS')})</option>"

opportunity_option_tag = (item) ->
  "<option value='#{item.get('OPPORTUNITY_ID')}'>#{item.get('OPPORTUNITY_NAME')} (#{item.get('OPPORTUNITY_STATE')})</option>"

users_option_tag = (item) ->
  "<option value='#{item.get('USER_ID')}'>#{item.get('FIRST_NAME')} #{item.get('LAST_NAME')}</option>"

Insightly.Views.Overlay = SB.Apps.BaseView.extend
  events: {
    'click a.submit': 'submit_form'
    'click a.cancel': 'cancel'
  }

  initialize: (options = {}) ->
    SB.Apps.BaseView.prototype.initialize.call(this, options)

    _.bindAll this,
              'render_projects',
              'render_one_project',
              'render_users',
              'render_one_user',
              'render_opportunities',
              'render_one_opportunity',
              'show_loading_indicator',
              'hide_loading_indicator'

    @setup_selectors()
    @populate_projects()
    @populate_users()
    @populate_opportunities()

  setup_selectors: ->
    @projects_selector = @$("[name='projects_select']")
    @opportunities_selector = @$("[name='opportunities_select']")
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
    @hide_loading_indicator()

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

  populate_opportunities: ->
    @opportunities = new SB.Apps.BaseCollection([], app: @app, endpoint: 'opportunities')
    @opportunities.on 'reset', @render_opportunities
    @opportunities.fetch()

  render_opportunities: ->
    @opportunities_selector.append "<option value='none'>None</option>"
    @opportunities.each @render_one_opportunity

  render_one_opportunity: (opportunity) ->
    @opportunities_selector.append opportunity_option_tag(opportunity)

  show_loading_indicator: ->
    @$("form").addClass("loading")

  hide_loading_indicator: ->
    @$("form").removeClass("loading")

  submit_form: ->
    @post 'button', @$('form').serializeJSON()

  cancel: ->
    @onClose()

return Insightly

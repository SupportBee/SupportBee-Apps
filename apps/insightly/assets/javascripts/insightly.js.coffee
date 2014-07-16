Insightly = {}
Insightly.Views = {}

option_tag = (item) ->
  "<option value='#{item.get('PROJECT_ID')}'>#{item.get('PROJECT_NAME')}</option>"

Insightly.Views.Overlay = SB.Apps.BaseView.extend(

  events: {
    'click a.submit': 'submit_form'
  }

  initialize: ->
    SB.Apps.BaseView.prototype.initialize.call(this)

    _.bindAll this, 'render_projects', 'render_one_project'
    @setup_selectors()
    @populate_projects()

  setup_selectors: ->
    @projects_selector = @$("[name='projects_select']")
    @title_el = @$(".title")
    @description_el = @$(".description")

  populate_projects: ->
    @projects = new SB.Apps.BaseCollection([], app: @app, endpoint: 'projects')
    @projects.on 'reset', @render_projects
    @projects.fetch()

  render_projects: ->
    console.log @projects
    @projects.each @render_one_project

  render_one_project: (project) ->
    @projects_selector.append option_tag(project)

  submit_form: ->
    @post 'button', @$('form').toJSON()

)

return Insightly

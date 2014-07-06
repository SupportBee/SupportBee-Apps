PivotalTracker = {}
PivotalTracker.Views = {}

option_tag = (item, options = {}) ->
  attribute_name  = options.attribute_name || 'name'
  attribute_id    = options.attribute_id || 'id'
  "<option value='#{item.get(attribute_id)}'>#{item.get(attribute_name)}</option>"

PivotalTracker.Views.Overlay = SB.Apps.BaseView.extend(

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
      @description_field = @$("[name='description']")
      @title_el = @$(".title")
      @description_el = @$(".description")

    populate_projects: ->
      @projects = new SB.Apps.BaseCollection([], app: @app, endpoint: 'projects')
      @projects.on 'reset', @render_projects
      @projects.fetch()

    render_projects: ->
      @projects.each @render_one_project

    render_one_project: ->
      @projects_selector.append option_tag(project)

)

return PivotalTracker

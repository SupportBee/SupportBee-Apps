Asana = {}
Asana.Views = {}

option_tag = (item, options = {}) ->
  attribute_name = options.attribute_name || 'name'
  attribute_id   = options.attribute_id || 'id'
  "<option value='#{item.get(attribute_id)}'>#{item.get(attribute_name)}</option>"


Asana.Views.Overlay = SB.Apps.BaseView.extend(

  events: {
    'change [name="org_select"]': 'org_changed',
    'change [name="projects_select"]': 'project_changed'
    'click a.submit': 'submit_form'
  }

  initialize: ->
    SB.Apps.BaseView.prototype.initialize.call(this)

    _.bindAll this, 'render_one_project', 'project_changed', 'render_orgs', 'render_one_org',
                    'render_projects', 'org_changed'

    @setup_selectors()
    @setup_projects_collection()
    @populate_orgs()

  setup_selectors: ->
    @orgs_selector = @$("[name='org_select']")
    @projects_selector = @$("[name='projects_select']")
    @todo_lists_selector = @$("[name='todo_lists']")
    @people_list_selector = @$("[name='assign_to']")
    @target_type_selector = @$("[name='type']")
    @description_field = @$("[name='description']")
    @title_el = @$(".title")
    @description_el = @$(".description")
    @todo_lists_el = @$(".todo_lists")
    @people_list_el = @$(".assign")
    @assign_el = @$(".assign")

  populate_orgs: ->
    @orgs = new SB.Apps.BaseCollection([], app: @app, endpoint: 'orgs')
    @orgs.on 'reset', @render_orgs
    @orgs.fetch()

  project_changed: ->

  setup_projects_collection: ->
    @projects = new SB.Apps.BaseCollection([], app: @app, endpoint: 'projects')
    @projects.on 'reset', @render_projects

  render_projects: ->
    @projects.each @render_one_project
  
  render_one_project: (project) ->
    @projects_selector.append option_tag(project)

  render_orgs: ->
    @orgs.each @render_one_org
    @load_org_projects()
  
  render_one_org: (org) ->
    @orgs_selector.append option_tag(org)

  hide_everything: ->
    @todo_lists_el.hide()
    @hide_description()
    @people_list_el.hide()

  org_changed: ->
    @reset_projects_list()
    @load_org_projects()

  reset_projects_list: ->
    @projects_selector.find('option').remove()

  load_org_projects: ->
    org = @orgs_selector.val()
    @projects.request_params = {org: org}
    @projects.fetch()

  submit_form: ->
    @post 'button', @$('form').toJSON()

)

return Asana

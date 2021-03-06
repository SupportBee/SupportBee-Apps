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
    'click a.cancel': 'cancel'
  }

  initialize: (options = {}) ->
    SB.Apps.BaseView.prototype.initialize.call(this, options)

    _.bindAll this, 'render_one_project', 'project_changed', 'render_orgs', 'render_one_org',
                    'render_projects', 'org_changed', 'render_people', 'render_person'

    @setup_selectors()
    @setup_projects_collection()
    @setup_people_collection()
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

  setup_people_collection: ->
    @workspace_users_list = new SB.Apps.BaseCollection([], app: @app, endpoint: 'workspace_users')
    @workspace_users_list.on 'reset', @render_people

  project_changed: ->

  setup_projects_collection: ->
    @projects = new SB.Apps.BaseCollection([], app: @app, endpoint: 'projects')
    @projects.on 'reset', @render_projects

  render_people: ->
    @workspace_users_list.each @render_person
    @people_list_el.show()

  render_person: (person) ->
    @people_list_selector.append option_tag(person)

  render_projects: ->
    @projects.each @render_one_project
  
  render_one_project: (project) ->
    @projects_selector.append option_tag(project)

  render_orgs: ->
    @orgs.each @render_one_org
    @load_org_projects()
    @load_org_people()
  
  render_one_org: (org) ->
    @orgs_selector.append option_tag(org)

  hide_everything: ->
    @todo_lists_el.hide()
    @hide_description()
    @people_list_el.hide()

  org_changed: ->
    @reset_projects_list()
    @reset_people_list()
    @load_org_projects()
    @load_org_people()

  reset_projects_list: ->
    @projects_selector.find('option').remove()

  reset_people_list: ->
    @people_list_el.find('option').remove()
    @append_default_option_on_reset()

  append_default_option_on_reset: ->
    @people_list_el.find('select').append('<option value="none">Don\'t Assign</option>')

  load_org_projects: ->
    org = @orgs_selector.val()
    @projects.request_params = {org: org}
    @projects.fetch()

  load_org_people: ->
    org = @orgs_selector.val()
    @workspace_users_list.request_params = {org: org}
    @workspace_users_list.fetch()

  submit_form: ->
    @post 'button', @$('form').serializeJSON()

  cancel: ->
    @onClose()

)

return Asana

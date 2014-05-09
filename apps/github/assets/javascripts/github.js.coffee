Github = {}
Github.Views = {}

option_tag = (item, attribute_name = 'name') ->
  "<option value='#{item.get('id')}'>#{item.get(attribute_name)}</option>"


Github.Views.Overlay = SB.Apps.BaseView.extend(

  events: {
    'change [name="org_select"]': 'org_changed',
    'change [name="projects_select"]': 'project_changed'
    'click a.submit': 'submit_form'
  }

  initialize: ->
    SB.Apps.BaseView.prototype.initialize.call(this)

    _.bindAll this, 'render_projects', 'target_changed', 'render_one_project',
                    'render_lists', 'render_one_list', 'project_changed',
                    'render_people', 'render_person', 'render_orgs', 'render_one_org'

    @setup_selectors()
    @populate_orgs()
    @populate_projects()

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

  populate_projects: ->
    @projects = new SB.Apps.BaseCollection([], app: @app, endpoint: 'projects')
    @projects.on 'reset', @load_personal_projects
    @projects.fetch()

  load_personal_projects: ->
    @projects.each @render_one_project
  
  render_one_project: (project) ->
    @projects_selector.append option_tag(project)

  render_orgs: ->
    @orgs.each @render_one_org
  
  render_one_org: (org) ->
    @orgs_selector.append option_tag(org, 'login')

  target_changed: ->
    @type = @target_type_selector.val()
    @hide_everything()
    switch @type
      when 'todo_item'
        @show_todo_lists_selector()
        @populate_lists()
        @populate_people()
      when 'todo_list'
        @hide_description()
      when 'message'
        @show_description()

  hide_everything: ->
    @todo_lists_el.hide()
    @hide_description()
    @people_list_el.hide()

  org_changed: ->
    @org = @orgs_selector.val()
    if @org == 'personal'
      @load_personal_projects()
    else
      @load_org_projects()

  submit_form: ->
    @post 'button', @$('form').toJSON()

)

return Github

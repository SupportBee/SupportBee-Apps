Pivotaltracker = {}
Pivotaltracker.Views = {}

option_tag = (item) ->
  "<option value='#{item.get('id')}'>#{item.get('name')}</option>"

Pivotaltracker.Views.Overlay = SB.Apps.BaseView.extend(

  events: {
    'change [name="projects_select"]': 'project_changed',
    'click a.submit': 'submit_form'
  }

  initialize: (options = {}) ->
    SB.Apps.BaseView.prototype.initialize.call(this, options)

    _.bindAll this, 'render_projects', 'render_one_project', 'render_memberships', 'render_one_membership', 'project_changed'

    @setup_selectors()
    @setup_memberships()
    @populate_projects()

  setup_selectors: ->
    @projects_selector = @$("[name='projects_select']")
    @story_owner_selector = @$("[name='story_owner']")
    @description_field = @$("[name='description']")
    @title_el = @$(".title")
    @description_el = @$(".description")
    @story_owner_el = @$(".story_owner")

  populate_projects: ->
    @projects = new SB.Apps.BaseCollection([], app: @app, endpoint: 'projects')
    @projects.on 'reset', @render_projects
    @projects.fetch()

  render_projects: ->
    @projects.each @render_one_project
    @load_memberships()

  render_one_project: (project) ->
    @projects_selector.append option_tag(project)

  project_changed: ->
    @reset_story_owner()
    @load_memberships()

  reset_story_owner: ->
    @story_owner_selector.find('option').remove().end().append('<option value="none">No Owner</option>').val("none")

  load_memberships: ->
    project = @projects_selector.val()
    @memberships.request_params = {projects_select: project}
    @memberships.fetch()

  setup_memberships: ->
    @memberships = new SB.Apps.BaseCollection([], endpoint: 'memberships', app: @app)
    @memberships.on 'reset', @render_memberships

  render_memberships: ->
    @memberships.each @render_one_membership

  render_one_membership: (member)->
    @story_owner_selector.append option_tag(member)

  submit_form: ->
    @post 'button', @$('form').toJSON()

)

return Pivotaltracker

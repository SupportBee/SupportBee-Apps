Clickup = {}
Clickup.Views = {}

option_tag = (item) ->
  "<option value='#{item.get('id')}'>#{item.get('name')}</option>"

option_tag_from_object = (item) ->
  "<option value='#{item.id}'>#{item.name}</option>"


Clickup.Views.Overlay = SB.Apps.BaseView.extend(
  events: {
    'change [name="team_select"]': 'on_team_select',
    'change [name="space_select"]': 'on_space_select',
    'change [name="project_select"]': 'on_project_select',
    'click a.submit': 'submit_form'
  }

  initialize: (options = {}) ->
    SB.Apps.BaseView.prototype.initialize.call(this, options)

    _.bindAll this,
      'initialize_variables',
      'populate_teams', 'render_teams', 'render_team', 'on_team_select',
      'populate_spaces', 'render_spaces', 'render_space', 'on_space_select',
      'populate_projects', 'render_projects', 'render_project', 'on_project_select',
      'populate_lists', 'render_lists', 'render_list',
      'populate_assignees', 'render_assignees', 'render_assignee',
      'populate_priority', 'render_priority',
      'show_loading_indicator', 'hide_loading_indicator',
      'submit_form'

    @initialize_variables()
    @populate_teams()
    @populate_priority()

  initialize_variables: ->
    @team_selector = @$("[name='team_select']")
    @space_selector = @$("[name='space_select']")
    @project_selector = @$("[name='project_select']")
    @list_selector = @$("[name='list_select']")
    @assignee_selector = @$("[name='assignee_select']")
    @priority_selector = @$("[name='priority_select']")

    @description_field = @$("[name='description']")
    @description_el = @$(".description")
    @title_el = @$(".title")

    @people_list_el = @$(".assign")

  populate_teams: ->
    ClickupTeams = SB.Apps.BaseCollection.extend(parse: (response) ->
      response.teams.teams
    )

    @teams = new ClickupTeams([], app: @app, endpoint: 'teams')
    @teams.on 'reset', @render_teams
    @teams.fetch()

  render_teams: ->
    @teams.each @render_team
    @populate_spaces()
    @populate_assignees()
    @hide_loading_indicator()

  render_team: (team) ->
    @team_selector.append option_tag(team)

  on_team_select: ->
    @show_loading_indicator()
    @populate_spaces()

  populate_spaces: ->
    selected_team_id = @team_selector.val()
    ClickupSpaces = SB.Apps.BaseCollection.extend(parse: (response) ->
      response.spaces.spaces
    )
    @spaces = new ClickupSpaces([],
      app: @app,
      endpoint: "spaces",
      request_params: { team_id: selected_team_id })
    @spaces.on 'reset', @render_spaces
    @spaces.fetch()

  render_spaces: ->
    @spaces.each @render_space
    @populate_projects()
    @hide_loading_indicator()

  render_space: (space) ->
    @space_selector.append option_tag(space)

  on_space_select: ->
    @show_loading_indicator()
    @populate_projects()

  populate_projects: ->
    selected_space_id = @space_selector.val()
    ClickupProjects = SB.Apps.BaseCollection.extend(parse: (response) ->
      response.projects.projects
    )
    @projects = new ClickupProjects([],
      app: @app,
      endpoint: "projects",
      request_params: { space_id: selected_space_id })
    @projects.on 'reset', @render_projects
    @projects.fetch()

  render_projects: ->
    @projects.each @render_project
    @populate_lists()
    @hide_loading_indicator()

  render_project: (project) ->
    @project_selector.append option_tag(project)

  on_project_select: ->
    @show_loading_indicator()
    @populate_lists()

  populate_lists: ->
    selected_project_id = @project_selector.val()
    project = @projects.find (project) ->
      project.get('id') == selected_project_id
    @lists = project.get('lists')
    @render_lists()

  render_lists: ->
    _.each @lists, @render_list
    @hide_loading_indicator()

  render_list: (list) ->
    @list_selector.append option_tag_from_object(list)

  populate_assignees: ->
    selected_team_id = @team_selector.val()
    team = @teams.find (team) ->
      team.get('id') == selected_team_id
    @assignees = team.get('members')
    @render_assignees()

  render_assignees: ->
    assignees = _.map @assignees, (assignee) ->
      user = assignee.user
      {
        id: user.id,
        name: user.username
      }
    _.each assignees, @render_assignee
    @hide_loading_indicator()

  render_assignee: (assignee) ->
    @assignee_selector.append option_tag_from_object(assignee)

  populate_priority: ->
    priorities = [{
      id: 1,
      name: 'Urgent'
    }, {
      id: 2,
      name: 'High'
    },{
      id: 3,
      name: 'Normal'
    }, {
      id: 4,
      name: 'Low'
    }]

    _.each priorities, @render_priority

  render_priority: (priority) ->
    @priority_selector.append option_tag_from_object(priority)

  show_loading_indicator: ->
    @$("form").addClass("loading")

  hide_loading_indicator: ->
    @$("form").removeClass("loading")
    $(window).resize()

  submit_form: ->
    console.log 'submit', @$('form').serializeJSON()
    @post 'button', @$('form').serializeJSON()
)

return Clickup

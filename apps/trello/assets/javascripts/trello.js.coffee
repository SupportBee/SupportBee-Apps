Trello = {}
Trello.Views = {}

option_tag = (item, options = {}) ->
  attribute_name = options.attribute_name || 'name'
  attribute_id   = options.attribute_id || 'id'
  "<option value='#{item.get(attribute_id)}'>#{item.get(attribute_name)}</option>"


Trello.Views.Overlay = SB.Apps.BaseView.extend(

  events: {
    'change [name="org_select"]': 'org_changed',
    'change [name="boards_select"]': 'project_changed'
    'click a.submit': 'submit_form'
  }

  initialize: ->
    SB.Apps.BaseView.prototype.initialize.call(this)

    _.bindAll this, 'render_one_board', 'project_changed', 'render_orgs',
                    'load_boards'

    @setup_selectors()
    #@populate_orgs()
    @populate_boards()

  setup_selectors: ->
    @orgs_selector = @$("[name='org_select']")
    @boards_selector = @$("[name='boards_select']")
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

  populate_boards: ->
    @boards = new SB.Apps.BaseCollection([], app: @app, endpoint: 'boards')
    @boards.on 'reset', @load_boards
    @boards.fetch()

  load_boards: ->
    @boards.each @render_one_board
  
  render_one_board: (board) ->
    @boards_selector.append option_tag(board)

  render_orgs: ->
    @orgs.each @render_one_org
  
  render_one_org: (org) ->
    @orgs_selector.append option_tag(org, attribute_name: 'login', attribute_id: 'login')

  hide_everything: ->
    @todo_lists_el.hide()
    @hide_description()
    @people_list_el.hide()

  org_changed: ->
    @org = @orgs_selector.val()
    if @org == 'personal'
      @load_personal_projects()
    else
      @reset_projects_list()
      @load_org_projects()

  reset_projects_list: ->
    @boards_selector.find('option').remove()

  load_org_projects: ->
    org = @orgs_selector.val()
    #@boards.request_params = {org: org}
    @boards.fetch()

  submit_form: ->
    @post 'button', @$('form').toJSON()

)

return Trello

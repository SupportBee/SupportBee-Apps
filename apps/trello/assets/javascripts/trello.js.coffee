Trello = {}
Trello.Views = {}

option_tag = (item, options = {}) ->
  attribute_name = options.attribute_name || 'name'
  attribute_id   = options.attribute_id || 'id'
  "<option value='#{item.get(attribute_id)}'>#{item.get(attribute_name)}</option>"


Trello.Views.Overlay = SB.Apps.BaseView.extend(

  events: {
    'change [name="org_select"]': 'org_changed',
    'change [name="boards_select"]': 'board_changed'
    'click a.submit': 'submit_form'
  }

  initialize: ->
    SB.Apps.BaseView.prototype.initialize.call(this)

    _.bindAll this, 'render_one_board', 'board_changed', 'render_orgs',
                    'render_boards', 'render_lists', 'render_one_list'

    @setup_selectors()
    @setup_lists()
    @populate_boards()

  setup_selectors: ->
    @lists_selector = @$("[name='lists_select']")
    @boards_selector = @$("[name='boards_select']")
    @description_field = @$("[name='description']")
    @title_el = @$(".title")
    @description_el = @$(".description")

  populate_orgs: ->
    @orgs = new SB.Apps.BaseCollection([], app: @app, endpoint: 'orgs')
    @orgs.on 'reset', @render_orgs
    @orgs.fetch()

  board_changed: ->
    @load_lists()

  load_lists: ->
    board = @boards_selector.val()
    @lists.request_params = {board: board}
    @lists.fetch()

  setup_lists: ->
    @lists = new SB.Apps.BaseCollection([], app: @app, endpoint: 'lists')
    @lists.on 'reset', @render_lists

  render_lists: ->
    @lists.each @render_one_list

  render_one_list: (list) ->
    @lists_selector.append option_tag(list)

  populate_boards: ->
    @boards = new SB.Apps.BaseCollection([], app: @app, endpoint: 'boards')
    @boards.on 'reset', @render_boards
    @boards.fetch()

  render_boards: ->
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

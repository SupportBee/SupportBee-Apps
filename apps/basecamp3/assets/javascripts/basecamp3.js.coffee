Basecamp = {}
Basecamp.Views = {}

option_tag = (item) ->
  "<option value='#{item.get('id')}'>#{item.get('name')}</option>"

Basecamp.Views.Overlay = SB.Apps.BaseView.extend(
  events: {
    'change [name="type"]': 'on_type_change',
    'change [name="projects_select"]': 'on_project_change'
    'click a.submit': 'submit_form'
  }

  initialize: (options = {}) ->
    SB.Apps.BaseView.prototype.initialize.call(this, options)

    _.bindAll @

    @initialize_variables()
    @populate_projects()

  initialize_variables: ->
    @projects_selector = @$("[name='projects_select']")
    @type_selector = @$("[name='type']")
    @todo_lists_selector = @$("[name='todo_lists']")
    @people_list_selector = @$("[name='assign_to']")

    @description_field = @$("[name='description']")

    @todo_lists_el = @$(".todo_lists")
    @title_el = @$(".title")
    @description_el = @$(".description")
    @people_list_el = @$(".assign")

  populate_projects: ->
    @projects = new SB.Apps.BaseCollection([], app: @app, endpoint: 'projects')
    @projects.on 'reset', @render_projects
    @projects.fetch()

  render_projects: ->
    @projects.each @render_project
    @hide_loading_indicator()

  render_project: (project) ->
    @projects_selector.append option_tag(project)

  on_project_change: ->
    @type_selector.children().first().attr('selected', 'selected')
    @hide_and_reset_todo_and_people_lists()

  on_type_change: ->
    @type = @type_selector.val()
    switch @type
      when 'message'
        @hide_and_reset_todo_and_people_lists()
      when 'todo_list'
        @hide_and_reset_todo_and_people_lists()
      when 'todo_item'
        @show_and_populate_todo_and_people_lists()

  hide_and_reset_todo_and_people_lists: ->
    @todo_lists_el.hide()
    @people_list_el.hide()
    @reset_todo_and_people_lists()

  show_and_populate_todo_and_people_lists: ->
    @show_todo_lists()
    @show_people_list()
    @populate_todo_lists()
    @populate_people()

  reset_todo_and_people_lists: ->
    @reset_todo_lists()
    @reset_people_list()

  reset_todo_lists: ->
    @todo_lists_el.find('option').remove().hide()

  reset_people_list: ->
    @people_list_el.find('option').remove().hide()

  show_title: ->
    @title_el.show()

  show_description: ->
    @description_el.show()

  show_todo_lists: ->
    @todo_lists_el.show()

  show_people_list: ->
    @people_list_el.show()

  populate_todo_lists: ->
    @todo_lists = new SB.Apps.BaseCollection([],
                                        endpoint: 'todo_lists',
                                        app: @app,
                                        request_params: {projects_select: @projects_selector.val()})
    @todo_lists.bind 'reset', @on_todo_lists_fetch
    @show_loading_indicator()
    @todo_lists.fetch()

  populate_people: ->
    @people_list = new SB.Apps.BaseCollection([],
                                              endpoint: 'project_members',
                                              app: @app,
                                              request_params: {projects_select: @projects_selector.val()})
    @people_list.bind 'reset', @on_people_list_fetch
    @show_loading_indicator()
    @people_list.fetch()

  on_todo_lists_fetch: ->
    @todo_lists.each @render_todo_list
    @todo_lists_fetched = true

    if @todo_lists_fetched && @people_list_fetched
      @hide_loading_indicator()
      # Reset variables
      @todo_lists_fetched = @people_list_fetched = false

  render_todo_list: (todo_list) ->
    @todo_lists_selector.append option_tag(todo_list)

  on_people_list_fetch: ->
    @people_list.each @render_person
    @people_list_fetched = true

    if @todo_lists_fetched && @people_list_fetched
      @hide_loading_indicator()
      # Reset variables
      @todo_lists_fetched = @people_list_fetched = false

  render_person: (person)->
    @people_list_selector.append option_tag(person)

  show_loading_indicator: ->
    @$("form").addClass("loading")

  hide_loading_indicator: ->
    @$("form").removeClass("loading")

  submit_form: ->
    formJSON = @$('form').toJSON()

    assignee_ids = this.$("select[name=assign_to]").parent().dropdown("get value")
    formJSON["assign_to"] = assignee_ids unless _.isEmpty(assignee_ids)

    @post 'button', formJSON
)

return Basecamp

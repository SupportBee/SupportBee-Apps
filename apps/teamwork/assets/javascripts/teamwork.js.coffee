Teamwork = {}
Teamwork.Views = {}

option_tag = (item) ->
  "<option value='#{item.get('id')}'>#{item.get('name')}</option>"

people_option_tag = (item) ->
  "<option value='#{item.get('id')}'>#{item.get('first-name').concat(" ", item.get('last-name'))}</option>"

Teamwork.Views.Overlay = SB.Apps.BaseView.extend(

  events: {
    'change [name="type"]': 'target_changed',
    'change [name="projects_select"]': 'project_changed'
    'click a.submit': 'submit_form'
  }

  initialize: (options = {}) ->
    SB.Apps.BaseView.prototype.initialize.call(this, options)

    _.bindAll this, 'render_projects', 'target_changed', 'render_one_project',
                    'render_lists', 'render_one_list', 'project_changed',
                    'render_people', 'render_person'

    @setup_selectors()
    @populate_projects()

  setup_selectors: ->
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

  populate_projects: ->
    @projects = new SB.Apps.BaseCollection([], app: @app, endpoint: 'projects')
    @projects.on 'reset', @render_projects
    @projects.fetch()

  render_projects: ->
    @projects.each @render_one_project

  render_one_project: (project) ->
    @projects_selector.append option_tag(project)

  target_changed: ->
    @type = @target_type_selector.val()
    @hide_everything()
    switch @type
      when 'todo_item'
        @show_todo_lists_selector()
        @populate_lists()
        @show_people_lists_selector()
        @populate_people()
      when 'todo_list'
        @reset_todo_lists()
        @reset_people_list()


  hide_everything: ->
    @todo_lists_el.hide()
    @people_list_el.hide()

  project_changed: ->
    @hide_everything()
    @reset_form()

  reset_form: ->
    @reset_type()
    
  reset_type: ->
    @target_type_selector.children().first().attr('selected','selected')
    @reset_todo_lists()
    @reset_people_list()
    @show_title()
    @show_description()

  reset_todo_lists: ->
    @todo_lists_el.find('option').remove().hide()

  reset_people_list: ->
    @people_list_el.find('option').remove().hide()
    @append_default_option_on_reset()

  append_default_option_on_reset: ->
    @people_list_el.find('select').append('<option value="none">Don\'t Assign</option>')

  show_title: ->
    @title_el.show()

  show_todo_lists_selector: ->
    @todo_lists_el.show()
 
  show_people_lists_selector: ->
    @people_list_el.show()

  populate_lists: ->
    @lists = new SB.Apps.BaseCollection([],
                                        endpoint: 'todo_lists',
                                        app: @app,
                                        request_params: {projects_select: @projects_selector.val()})
    @lists.bind 'reset', @render_lists
    @lists.fetch()

  populate_people: ->
    @people_list = new SB.Apps.BaseCollection([],
                                              endpoint: 'project_accesses',
                                              app: @app,
                                              request_params: {projects_select: @projects_selector.val()})
    @people_list.bind 'reset', @render_people
    @people_list.fetch()

  render_people: ->
    @people_list.each @render_person
    @people_list_el.show()

  render_person: (person)->
    @people_list_selector.append people_option_tag(person)
    

  render_lists: ->
    @lists.each @render_one_list
    @todo_lists_el.show()

  render_one_list: (list) ->
    @todo_lists_selector.append option_tag(list)


  submit_form: ->
    @post 'button', @$('form').toJSON()

)

return Teamwork

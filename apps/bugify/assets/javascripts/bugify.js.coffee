Bugify = {}
Bugify.Views = {}

option_tag = (item) ->
  "<option value='#{item.get('id')}'>#{item.get('name')}</option>"

Bugify.Views.Overlay = SB.Apps.BaseView.extend(

  events: {
    'click a.submit': 'submit_form'
  }

  initialize: ->
    SB.Apps.BaseView.prototype.initialize.call(this)

    _.bindAll this, 'render_projects', 'render_one_project',
                    'render_lists', 'render_one_list',
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
    console.log @projects
    @projects.each @render_one_project

  render_one_project: (project) ->
    @projects_selector.append option_tag(project)

  reset_type: ->
    @target_type_selector.children().first().attr('selected','selected')
    @reset_todo_lists()
    @show_title()
    @show_description()

  reset_todo_lists: ->
    @todo_lists_el.find('option').remove().hide()

  show_title: ->
    @title_el.show()

  show_description: ->
    @description_el.show()

  show_todo_lists_selector: ->
    @todo_lists_el.show()    
 
  hide_description: ->
    @description_el.hide()
 
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
    @people_list_selector.append option_tag(person)
    

  render_lists: ->
    console.log 'render_lists', @lists
    @lists.each @render_one_list
    @todo_lists_el.show()
    @description_el.hide()

  render_one_list: (list) ->
    @todo_lists_selector.append option_tag(list)


  submit_form: ->
    @post 'button', @$('form').toJSON()

)

return Bugify

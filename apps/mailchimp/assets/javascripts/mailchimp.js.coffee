MailChimp = {}
MailChimp.Views = {}

option_tag = (list) ->
  "<option value='#{list.get('id')}'>#{list.get('name')}</option>"

MailChimp.Views.Overlay = SB.Apps.BaseView.extend(

  events: {
    'click a.submit': 'submit_form'
  }

  initialize: -> 
    SB.Apps.BaseView.prototype.initialize.call(this)
    _.bindAll this, 'load_lists', 'render_list'
    @setup_selectors()
    @populate_lists()

  setup_selectors: ->
    @lists_selector = @$("[name='lists_select']")

  populate_lists: ->
    @lists = new SB.Apps.BaseCollection([], app: @app, endpoint: 'lists')
    @lists.on 'reset', @load_lists
    @lists.fetch()

  load_lists: ->
    @lists.each @render_list

  render_list: (list) ->
    @lists_selector.append option_tag(list)

  submit_form: ->
    @post 'button', @$('form').toJSON()

)

return MailChimp

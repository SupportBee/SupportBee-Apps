module CreateSnippet
  module ActionHandler
    def button
     begin
       create_snippet(name: payload.overlay.name, text: payload.overlay.text, tags: payload.overlay.tags)
     rescue Exception => e
       context = { payload: payload }
       ErrorReporter.report(e, context: context)
       return [500, e.message]
     end

      [200, "Snippet created! Reload the page to access it."]
    end
  end
end

module CreateSnippet
  class NameCannotBeBlank < ::StandardError
    def message
      "Name cannot be blank"
    end
  end

  class TextCannotBeBlank < ::StandardError
    def message
      "Text cannot be blank"
    end
  end

  class Base < SupportBeeApp::Base

    private

    def create_snippet(params={})
      raise NameCannotBeBlank if params[:name].blank?
      raise TextCannotBeBlank if params[:text].blank?
      snippet = SupportBee::Snippet.create(auth, params)
    end
  end
end

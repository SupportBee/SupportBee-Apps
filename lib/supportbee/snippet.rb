module SupportBee
  class Snippet < Resource
    class << self
      def list(auth={}, params={})
        response = api_get(resource_url, auth, params)
        snippets_array_from_multi_response(response, auth)
      end

      def create(auth={},params={})
        snippet_attributes = {:content_attributes => {}}
        snippet_attributes[:tags] = params.delete(:tags) if params[:tags]
        snippet_attributes[:name] = params.delete(:name)
        snippet_attributes[:content_attributes][:body] = params.delete(:text) if params[:text]
        snippet_attributes[:content_attributes][:body_html] = params.delete(:html) if params[:html]
       
        post_body = {:snippet => snippet_attributes}
        response = api_post(resource_url,auth,{body: post_body})
        self.new(auth,response.body['snippet'])
      end

      private

      def snippets_array_from_multi_response(response, auth)
        snippets = []
        result = Hashie::Mash.new
        response.body.keys.each do |key|
          if key == 'snippets'
            response.body[key].each do |snippet|
              snippets << self.new(auth,snippet)
            end
          else
            result[key] = response.body[key]
          end
        end
        result.snippets = snippets
        result
      end
    end
  end
end

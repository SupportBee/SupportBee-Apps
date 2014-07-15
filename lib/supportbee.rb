module SupportBee
   class InvalidAuthToken < ::StandardError; end
   class InvalidSubDomain < ::StandardError; end
   class InvalidRequestError < ::StandardError; end

  class Base
    
    extend HttpHelper
    include HttpHelper

    class << self
      def class_name
        self.name.split('::')[-1]
      end

      def create_method(name, &block)
        self.send(:define_method, name, &block)
      end

      def api_endpoint(subdomain)
        "#{APP_CONFIG['core_app_protocol']}://#{subdomain}.#{APP_CONFIG['core_app_base_domain']}:#{APP_CONFIG['core_app_port']}"
      end

      def default_headers
        {'Accept' => 'application/json'}
      end

      def api_get(resource_url,auth={},params={})
        validate_auth(auth)
        params[:auth_token] = auth[:auth_token]
        url = "#{api_endpoint(auth[:subdomain])}#{resource_url}"
        http_get(url, params, default_headers)
      end

      def api_post(resource_url,auth={},params={})
        validate_auth(auth)
        url = "#{api_endpoint(auth[:subdomain])}#{resource_url}"
        http_post(url, params[:body], default_headers) do |req|
          req.params[:auth_token] = auth[:auth_token]
        end
      end

      def api_put(resource_url,auth={},params={})
        validate_auth(auth)
        url = "#{api_endpoint(auth[:subdomain])}#{resource_url}"
        http_method(:put, url, params[:body], default_headers) do |req|
          req.params[:auth_token] = auth[:auth_token]
        end
      end

      def api_delete(resource_url,auth={},params={})
        validate_auth(auth)
        url = "#{api_endpoint(auth[:subdomain])}#{resource_url}"
        http_method(:delete, url, nil, default_headers) do |req|
          req.params[:auth_token] = auth[:auth_token]
        end
      end

      private

      def validate_auth(auth)
        raise InvalidAuthToken if auth[:auth_token].blank?
        raise InvalidSubDomain if auth[:subdomain].blank?
      end
    end

    attr_reader :attributes
    
    def initialize(data={}, payload={})
      raise NotImplementedError.new('SupportBee::Base is an abstract class.  You should perform actions on its subclasses (Ticket, Reply, etc.)') if self.class == SupportBee::Base
      @params = Hashie::Mash.new(data)
      raise InvalidAuthToken if @params[:auth_token].blank?
      raise InvalidSubDomain if @params[:subdomain].blank?
      load_attributes(Hashie::Mash.new(payload))
    end

    def api_endpoint
      @api_endpoint ||= self.class.api_endpoint(@params[:subdomain])
    end

    def default_params
      {}
    end

    def auth
      @auth ||= Hashie::Mash.new({ :auth_token => @params[:auth_token], :subdomain => @params[:subdomain] })
    end

    def default_headers
      self.class.default_headers    
    end

    def api_get(resource_url, params={})
      params = default_params.merge(params)
      self.class.api_get(resource_url, auth, params)
    end

    def api_post(resource_url, params={})
      params = default_params.merge({:body => params[:body]})
      self.class.api_post(resource_url, auth, params)
    end

    def api_put(resource_url, params={})
      params = default_params.merge({:body => params[:body]})
      self.class.api_put(resource_url, auth, params)
    end

    def api_delete(resource_url, params={})
      params = default_params.merge(params)
      self.class.api_delete(resource_url, auth, params)
    end

    protected

    def load_attributes(hash)
      @attributes = Hashie::Mash.new(hash)

      if @attributes[:content]
        pre_process_content(@attributes[:content])
      end

      hash.keys.each do |key|          
        self.class.create_method(key) { @attributes.send(key) }
        self.class.create_method("#{key}=") { |value| @attributes.send("#{key}=", value) }
      end
    end

    def pre_process_content(content_hash)
      if content_hash.is_a?(Hash) and content_hash.has_key?(:text) and content_hash.has_key?(:html)
        content_hash.text = CGI::unescapeHTML(content_hash.text)
        content_hash.html = CGI::unescapeHTML(content_hash.html) unless content_hash.html.blank?
      end
    end
  end
end

require_relative 'supportbee/company'
require_relative 'supportbee/resource'
require_relative 'supportbee/label'
require_relative 'supportbee/user'
require_relative 'supportbee/group'
require_relative 'supportbee/assignment'
require_relative 'supportbee/reply'
require_relative 'supportbee/comment'
require_relative 'supportbee/ticket'
require_relative 'supportbee/snippet'

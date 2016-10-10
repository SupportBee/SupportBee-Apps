module SupportBee
  class Resource < Base
    class << self
      def key
        @key || class_name.downcase
      end

      def key=(value)
        @key = value
      end

      def resource_url
        if self == Resource
          raise NotImplementedError.new('APIResource is an abstract class.  You should perform actions on its subclasses (Ticket, Reply, etc.)')
        end
        "/#{CGI.escape(key)}s"
      end
    end

    attr_reader :current_company

    def initialize(data={}, payload={})
      super(data, payload)
      @current_company = SupportBee::Company.new(@params, @params[:current_company]) if @params[:current_company]
    end

    def resource_url
      unless id
        raise InvalidRequestError.new("Could not determine which URL to request: #{self.class} instance has invalid ID: #{id.inspect}", 'id')
      end
      "#{self.class.resource_url}/#{id}"
    end

    def refresh
      response = api_get(resource_url)
      begin
        load_attributes(response.body[self.class.key])
      rescue => e
        ErrorReporter.report(e, {body: response && response.body})
        LOGGER.warn "__REFRESH_FAILED__#{e.message}"
        LOGGER.warn "__REFRESH_FAILED__#{e.backtrace}"
        LOGGER.warn "__REFRESH_FAILED__#{response.status}" if response.respond_to?(:status)
        LOGGER.warn "__REFRESH_FAILED__#{response.body}" if response.respond_to?(:body)
      end
      self
    end
  end
end

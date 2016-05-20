module SupportBee
  module ProxyEventHandler

    private

    def method_missing(method_name, *args)
      all_events
    end

    def respond_to?(method_name)
      defined?(payload) && method_name =~ /^[\w_]+$/
    end
  end
end

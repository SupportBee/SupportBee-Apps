module Sidekiq
  module Middleware
    module Server

      ##
      # Send Sidekiq job metrics to a statsd server.
      #
      # Stats are namespaced by Worker class name:
      #
      #   jobs.WorkerClassName.count (counter)
      #   jobs.WorkerClassName.success (counter)
      #   jobs.WorkerClassName.failure (counter)
      #   jobs.WorkerClassName.perform (time gauge)
      #
      # Also sets global counters for tracking total job counts:
      #
      #   jobs.count
      #   jobs.success
      #   jobs.failure
      class Statsd
        def initialize(options={})
          @statsd = options[:client] || raise("statsd support requires a :client option")
        end

        def call(worker, msg, queue, &block)
          w = msg['wrapped'.freeze] || worker.class.to_s
          begin
            @statsd.increment("jobs.count")
            @statsd.increment("jobs.#{w}.count")
            @statsd.time("jobs.#{w}.perform", &block)
            @statsd.increment("jobs.success")
            @statsd.increment("jobs.#{w}.success")
          rescue Exception
            @statsd.increment("jobs.failure")
            @statsd.increment("jobs.#{w}.failure")
            raise
          end
        end
      end
    end
  end
end

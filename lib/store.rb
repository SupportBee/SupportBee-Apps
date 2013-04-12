module SupportBeeApp
  class Store

    attr_reader :redis, :redis_key_prefix

    def initialize(options={}) 
      @redis = options.delete(:redis) || REDIS  
      @redis_key_prefix = options.delete(:redis_key_prefix) || ''
    end

    def set(key, value)
      redis.set(redis_key(key), value)
    end

    def get(key)
      redis.get(redis_key(key))
    end

    private

    def redis_key(key)
      "#{redis_key_prefix}:#{key}"
    end
  end
end

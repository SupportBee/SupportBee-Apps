require 'spec_helper'

describe SupportBeeApp::Store do

  def store(options = {})
    SupportBeeApp::Store.new(options)
  end

  describe "Initialization" do
    describe "Redis" do
      it "should default to REDIS" do
        store.redis.should == REDIS
      end

      it "should accept a redis cilent instance" do
        redis_client = MockRedis.new(db: 10)
        store(redis: redis_client).redis.should == redis_client
      end

      it "should default redis key prefix to an empty string" do
        store.redis_key_prefix.should == ''
      end

      it "should accept a redis key prefix" do
        store(redis_key_prefix: 'prefix').redis_key_prefix.should == 'prefix'
      end
    end
  end

  describe "Instance Methods" do
    it "should set a value with the right key" do
      redis_store = store(redis_key_prefix: 'prefix')
      flexmock(redis_store.redis).should_receive(:set).with('prefix:key', 1).once
      redis_store.set('key', 1)
    end

    it "should get a value with the right key" do
      redis_store = store(redis_key_prefix: 'prefix')
      flexmock(redis_store.redis).should_receive(:get).with('prefix:key').once
      redis_store.get('key') 
    end
  end
end

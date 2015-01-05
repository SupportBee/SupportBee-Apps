require 'spec_helper'

describe SupportBeeApp::Base do
  describe "ClassMethods" do
		describe "Variables" do
      it "should respond to env" do
			  Dummy::Base.env.should == 'test'
		  end

      it "should have env helper methods" do
        Dummy::Base.should be_test
      end

      it "should set name" do
        Dummy::Base.name.should == 'Dummy'
      end 

      it "should set slug" do
        Dummy::Base.slug.should == 'dummy'
      end
    end

    describe "Paths" do
      it "should figure out the root from the class name" do
        Dummy::Base.root.to_s.should == "#{APPS_PATH}/dummy"
      end

      it "should set the assets path" do
        Dummy::Base.assets_path.to_s.should == "#{APPS_PATH}/dummy/assets"
      end

      it "should set the views path" do
        Dummy::Base.views_path.to_s.should == "#{APPS_PATH}/dummy/assets/views"
      end
    end

    describe "Configuration" do
      it "should load configurations from config.yml" do
        Dummy::Base.configuration['name'].should == 'Dummy'
        Dummy::Base.configuration['slug'].should == 'dummy'
      end
    end

    describe "Schema" do
      it "should have the right schema" do
        Dummy::Base.schema.should == {
          'name' => {'type' => 'string', 'label' => 'Name', 'required' => true, 'hint' => 'A Dummy Name'},
          'key' => {'type' => 'password', 'label' => 'Token', 'required' => true},
          'active' => {'type' => 'boolean', 'label' => 'Active', 'required' => false,'default' => true },
        }
      end
    end

    describe "api_hash" do
      it "should have the right event handler methods" do
        expect(Dummy::Base.api_hash['events']).to eq(['ticket.created', 'ticket.updated', 'reply.created', 'reply.updated', 'all.events'])
      end
    end

  end

  describe "Instance" do
    def create_dummy_instance
      Dummy::Base.new({auth:{subdomain: 'subdomain'}})
    end

    it "should have all event handler methods" do
      create_dummy_instance.should respond_to('ticket_created')
    end

    it "should have all action handler methods" do
      create_dummy_instance.should respond_to('button')
    end

    it "should have a store" do
      app = create_dummy_instance 
      app.store.should be_kind_of(SupportBeeApp::Store)
      app.store.redis_key_prefix.should == "#{app.class.slug}:#{app.auth.subdomain}"
    end

    describe "Validation" do
      describe "#valid?" do
        context "does not respond to validate" do
          it "returns true" do
            dummy = create_dummy_instance
            dummy.should be_valid
          end
        end

        context "responds to validate" do
          it "calls the validate method" do
            dummy = create_dummy_instance
            def dummy.validate; end;
            flexmock(dummy).should_receive(:validate).and_return(true).once
            dummy.valid?
          end
        end
      end
    end

    describe "Receive" do
      context "Event" do
        it "should trigger an event" do
          dummy = create_dummy_instance
          flexmock(dummy).should_receive(:ticket_created).once
          dummy.trigger_event('ticket.created')
        end

        it "should trigger all_events for any event" do
          dummy = create_dummy_instance
          flexmock(dummy).should_receive(:all_events).once
          dummy.trigger_event('ticket.created')
        end

        it "should silently fail if the app does not handle the event" do
          dummy = create_dummy_instance
          lambda{
            dummy.trigger_event('blah')
          }.should_not raise_error
        end
      end
      context "Action" do 
        it "should trigger a action" do
          dummy = create_dummy_instance
          flexmock(dummy).should_receive(:action_button).once
          dummy.trigger_action('action_button')
        end

        it "should trigger all_actions for any action" do
          dummy = create_dummy_instance
          flexmock(dummy).should_receive(:all_actions).once
          dummy.trigger_action('action_button')
        end

        it "should silently fail if the app does not handle an action" do
          dummy = create_dummy_instance
          lambda{
            dummy.trigger_action('blah')
          }.should_not raise_error
        end
      end
    end
  end
end

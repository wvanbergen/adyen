require "#{File.dirname(__FILE__)}/spec_helper.rb"

require 'action_controller'
require 'action_controller/test_process'

describe Adyen::Notification do

  before(:all) do
    ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')

    ActiveRecord::Migration.verbose = false
    Adyen::Notification::Migration.up    
  end
  
  after(:all) do
    Adyen::Notification::Migration.down
  end

  describe Adyen::Notification::HttpPost do

    describe 'payment authorization' do
          
      before(:each) do
        @request = mock('request')
        @request.stub!(:params).and_return({
              "merchantAccountCode"=>"FloorPlannerNL", "eventCode"=>"AUTHORISATION", 
              "paymentMethod"=>"mc", "eventDate"=>"2009-08-10T09:00:08.04Z", 
              "operations"=>"CANCEL,CAPTURE,REFUND", "merchantReference"=>"4", 
              "action"=>"process_adyen", "live"=>"false", "controller"=>"payment_notifications", 
              "value"=>"2500", "success"=>"true", "reason"=>"10676:1111:12/2012", 
              "originalReference"=>"", "pspReference"=>"8712498948081194", "currency"=>"USD"})

        @notification = Adyen::Notification::HttpPost.log(@request)
      end
      
      it "should have saved the notification record" do
        @notification.should_not be_new_record
      end
    
      it "should be an authorization" do
        @notification.should be_authorisation
      end
    
      it "should convert the amount to a bigdecimal" do
        @notification.value.should eql(BigDecimal.new('25.00'))
      end
      
      it "should convert live to a boolean" do
        @notification.should_not be_live
      end
      
      it "should convert success to a boolean" do
        @notification.should be_success
      end
      
      it "should be a successfull authorization" do
        @notification.should be_successful_authorization
      end
      
      it "should convert the eventDate" do
        @notification.event_date.should be_kind_of(Time)
      end
      
      it "should convert the empty original reference to NULL" do
        @notification.original_reference.should be_nil
      end      
      
    end
  end

end

require "#{File.dirname(__FILE__)}/spec_helper.rb"

require 'action_controller'
require 'action_controller/test_process'

describe Adyen::Notification do

  describe Adyen::Notification::HttpPost do

    context 'creation' do
      before(:each) do
        @request = mock('request')
        @request.stub!(:params).and_return(
            :live => 'false', :eventCode => 'AUTHORISATION', :pspReference => '1234', 
            :merchantReference => '5678', :merchantAccountCode => 'MyAccountCode', 
            :eventDate => '2009-01-02', :success => 'true', :paymentMethod => 'ideal', 
            :operations => 'REFUND', :currency => 'EUR', :value => '4450')
        
        @notification = Adyen::Notification::HttpPost.new(@request)
      end
    
      it "should convert the amount to a bigdecimal" do
        @notification.value.should eql(BigDecimal.new('44.50'))
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
      
      it "should be an :authorisation event" do
        @notification.event.should eql(:authorisation)
      end
      
    end
  end

end

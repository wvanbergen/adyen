require "#{File.dirname(__FILE__)}/spec_helper.rb"

describe Adyen::Form do
  
  describe 'Adyen urls' do
    it "should generate correct testing url" do
      Adyen::Form.url.should eql('https://test.adyen.com/hpp/select.shtml')
    end
  
    it "should generate correct live url in a production environment" do
      Adyen.stub!(:autodetect_environment).and_return('live')
      Adyen::Form.url.should eql('https://live.adyen.com/hpp/select.shtml')
    end

    it "should generate correct live url if explicitely asked for" do
      Adyen::Form.url('live').should eql('https://live.adyen.com/hpp/select.shtml')
    end
  end  
  
  describe 'hidden fields generation' do
    
    include ActionView::Helpers::TagHelper
  
    
    before(:each) do
      @attributes = { :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.today, 
        :merchant_reference => 'Internet Order 12345', :skin_code => '4aD37dJA', 
        :merchant_account => 'TestMerchant', :session_validity => 1.hour.from_now }      
    end
    
    it "should generate a valid payment form" do
      content_tag(:form, Adyen::Form.hidden_fields(@attributes.merge(:shared_secret => 'secret')),
          :action => Adyen::Form.url, :method => :post).should have_adyen_payment_form
    end
  end
  
  describe 'signature calculation' do

    # This example is taken from the Adyen integration manual 

    before(:each) do      
      @attributes = { :currency_code => 'GBP', :payment_amount => 10000,
        :ship_before_date => '2007-10-20', :merchant_reference => 'Internet Order 12345',
        :skin_code => '4aD37dJA', :merchant_account => 'TestMerchant', 
        :session_validity => '2007-10-11T11:00:00Z' }  
    
      Adyen::Form.do_attribute_transformations!(@attributes) 
    end
  
    it "should construct the signature string correctly" do
      signature_string = Adyen::Form.calculate_signature_string(@attributes)
      signature_string.should eql("10000GBP2007-10-20Internet Order 123454aD37dJATestMerchant2007-10-11T11:00:00Z")
    end
  
    it "should calculate the signature correctly" do
      signature = Adyen::Form.calculate_signature(@attributes.merge(:shared_secret => 'Kah942*$7sdp0)'))
      signature.should eql('x58ZcRVL1H6y+XSeBGrySJ9ACVo=')    
    end

    it "should calculate the signature correctly for a recurring payment" do
      # Add the required recurrent payment attributes      
      @attributes.merge!(:recurring_contract => 'DEFAULT', :shopper_reference => 'grasshopper52', :shopper_email => 'gras.shopper@somewhere.org')
      
      signature_string = Adyen::Form.calculate_signature_string(@attributes)
      signature_string.should eql("10000GBP2007-10-20Internet Order 123454aD37dJATestMerchant2007-10-11T11:00:00Zgras.shopper@somewhere.orggrasshopper52DEFAULT")
    end
    
    it "should calculate the signature correctly for a recurring payment" do
      # Add the required recurrent payment attributes
      @attributes.merge!(:recurring_contract => 'DEFAULT', :shopper_reference => 'grasshopper52', :shopper_email => 'gras.shopper@somewhere.org')
      
      signature = Adyen::Form.calculate_signature(@attributes.merge(:shared_secret => 'Kah942*$7sdp0)'))
      signature.should eql('F2BQEYbE+EUhiRGuPtcD16Gm7JY=')    
    end
    
  end
  
end
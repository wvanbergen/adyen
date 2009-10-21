require "#{File.dirname(__FILE__)}/spec_helper.rb"

describe Adyen::Form do

  before(:all) do
    Adyen::Form.register_skin(:testing, '4aD37dJA', 'Kah942*$7sdp0)')
    Adyen::Form.default_parameters[:merchant_account] = 'TestMerchant'
  end

  describe 'Action URLs' do

    before(:each) do
      # Use autodetection for the environment unless otherwise specified
      Adyen.environment = nil
    end

    it "should generate correct the testing url" do
      Adyen::Form.url.should eql('https://test.adyen.com/hpp/select.shtml')
    end

    it "should generate a live url if the environemtn is set top live" do
      Adyen.environment = :live
      Adyen::Form.url.should eql('https://live.adyen.com/hpp/select.shtml')
    end

    it "should generate correct live url in a production environment" do
      Adyen.stub!(:autodetect_environment).and_return('live')
      Adyen::Form.url.should eql('https://live.adyen.com/hpp/select.shtml')
    end

    it "should generate correct live url if explicitely asked for" do
      Adyen::Form.url(:live).should eql('https://live.adyen.com/hpp/select.shtml')
    end
  end

  describe 'redirect signature check' do
    before(:each) do
      # Example taken from integration manual

      # Example get params sent back with redirect
      @params = { :authResult => 'AUTHORISED', :pspReference => '1211992213193029',
        :merchantReference => 'Internet Order 12345', :skinCode => '4aD37dJA',
        :merchantSig => 'ytt3QxWoEhAskUzUne0P5VA9lPw='}
    end

    it "should calculate the signature string correctly" do
      Adyen::Form.redirect_signature_string(@params).should eql('AUTHORISED1211992213193029Internet Order 123454aD37dJA')
    end

    it "should calculate the signature correctly" do
      Adyen::Form.redirect_signature(@params).should eql(@params[:merchantSig])
    end

    it "should check the signature correctly with explicit shared signature" do
      Adyen::Form.redirect_signature_check(@params, 'Kah942*$7sdp0)').should be_true
    end

    it "should check the signature correctly using the stored shared secret" do
      Adyen::Form.redirect_signature_check(@params).should be_true
    end


    it "should detect a tampered field" do
      Adyen::Form.redirect_signature_check(@params.merge(:pspReference => 'tampered')).should be_false
    end

    it "should detect a tampered signature" do
      Adyen::Form.redirect_signature_check(@params.merge(:merchantSig => 'tampered')).should be_false
    end

  end

  describe 'redirect URL generation' do
    before(:each) do
      @attributes = { :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.today,
        :merchant_reference => 'Internet Order 12345', :skin => :testing,
        :session_validity => 1.hour.from_now }

      @redirect_url = Adyen::Form.redirect_url(@attributes)
    end
    
    it "should return an URL pointing to the adyen server" do
      @redirect_url.should =~ %r[^#{Adyen::Form.url}]
    end
    
    it "should include all provided attributes" do
      params = @redirect_url.split('?', 2).last.split('&').map { |param| param.split('=', 2).first }
      params.should include(*(@attributes.keys.map { |k| k.to_s.camelize(:lower) }))
    end
    
    it "should include the merchant signature" do
      params = @redirect_url.split('?', 2).last.split('&').map { |param| param.split('=', 2).first }
      params.should include('merchantSig')
    end
  end

  describe 'hidden fields generation' do

    include ActionView::Helpers::TagHelper

    before(:each) do
      @attributes = { :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.today,
        :merchant_reference => 'Internet Order 12345', :skin => :testing,
        :session_validity => 1.hour.from_now }
    end

    it "should generate a valid payment form" do
      content_tag(:form, Adyen::Form.hidden_fields(@attributes),
          :action => Adyen::Form.url, :method => :post).should have_adyen_payment_form
    end
  end

  describe 'signature calculation' do

    # This example is taken from the Adyen integration manual

    before(:each) do

      @parameters = { :currency_code => 'GBP', :payment_amount => 10000,
        :ship_before_date => '2007-10-20', :merchant_reference => 'Internet Order 12345',
        :skin => :testing, :session_validity => '2007-10-11T11:00:00Z' }

      Adyen::Form.do_parameter_transformations!(@parameters)
    end

    it "should construct the signature string correctly" do
      signature_string = Adyen::Form.calculate_signature_string(@parameters)
      signature_string.should eql("10000GBP2007-10-20Internet Order 123454aD37dJATestMerchant2007-10-11T11:00:00Z")
    end
    
    it "should calculate the signature correctly" do
      signature = Adyen::Form.calculate_signature(@parameters)
      signature.should eql('x58ZcRVL1H6y+XSeBGrySJ9ACVo=')
    end

    it "should calculate the signature correctly for a recurring payment" do
      # Add the required recurrent payment attributes
      @parameters.merge!(:recurring_contract => 'DEFAULT', :shopper_reference => 'grasshopper52', :shopper_email => 'gras.shopper@somewhere.org')

      signature_string = Adyen::Form.calculate_signature_string(@parameters)
      signature_string.should eql("10000GBP2007-10-20Internet Order 123454aD37dJATestMerchant2007-10-11T11:00:00Zgras.shopper@somewhere.orggrasshopper52DEFAULT")
    end

    it "should calculate the signature correctly for a recurring payment" do
      # Add the required recurrent payment attributes
      @parameters.merge!(:recurring_contract => 'DEFAULT', :shopper_reference => 'grasshopper52', :shopper_email => 'gras.shopper@somewhere.org')

      signature = Adyen::Form.calculate_signature(@parameters)
      signature.should eql('F2BQEYbE+EUhiRGuPtcD16Gm7JY=')
    end
  end
end
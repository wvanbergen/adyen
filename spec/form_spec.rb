# encoding: UTF-8

require 'spec_helper'
require 'adyen/form'

describe Adyen::Form do

  before(:all) do
    Adyen.configuration.register_form_skin(:testing, '4aD37dJA', 'Kah942*$7sdp0)')
    Adyen.configuration.default_form_params[:merchant_account] = 'TestMerchant'
  end

  describe 'Action URLs' do

    before(:each) do
      # Use autodetection for the environment unless otherwise specified
      Adyen.configuration.environment = nil
    end

    it "should generate correct the testing url" do
      case Adyen.configuration.payment_flow
        when 'select.shtml'
          Adyen::Form.url.should == 'https://test.adyen.com/hpp/select.shtml'
        when 'pay.shtml'
          Adyen::Form.url.should == 'https://test.adyen.com/hpp/pay.shtml'
        when 'details.shtml'
          Adyen::Form.url.should == 'https://test.adyen.com/hpp/details.shtml'
      end
    end

    it "should generate a live url if the environemtn is set top live" do
      Adyen.configuration.environment = :live
      case Adyen.configuration.payment_flow
        when 'select.shtml'
          Adyen::Form.url.should == 'https://live.adyen.com/hpp/select.shtml'
        when 'pay.shtml'
          Adyen::Form.url.should == 'https://live.adyen.com/hpp/pay.shtml'
        when 'details.shtml'
          Adyen::Form.url.should == 'https://live.adyen.com/hpp/details.shtml'
      end
    end

    it "should generate correct live url in a production environment" do
      Adyen.configuration.stub!(:autodetect_environment).and_return('live')
      case Adyen.configuration.payment_flow
        when 'select.shtml'
          Adyen::Form.url.should == 'https://live.adyen.com/hpp/select.shtml'
        when 'pay.shtml'
          Adyen::Form.url.should == 'https://live.adyen.com/hpp/pay.shtml'
        when 'details.shtml'
          Adyen::Form.url.should == 'https://live.adyen.com/hpp/details.shtml'
      end
    end

    it "should generate correct live url if explicitely asked for" do
      case Adyen.configuration.payment_flow
        when 'select.shtml'
          Adyen::Form.url(:live).should == 'https://live.adyen.com/hpp/select.shtml'
        when 'pay.shtml'
          Adyen::Form.url(:live).should == 'https://live.adyen.com/hpp/pay.shtml'
        when 'details.shtml'
          Adyen::Form.url(:live).should == 'https://live.adyen.com/hpp/details.shtml'
      end
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
      Adyen::Form.redirect_signature_string(@params).should == 'AUTHORISED1211992213193029Internet Order 123454aD37dJA'
    end

    it "should calculate the signature correctly" do
      Adyen::Form.redirect_signature(@params).should == @params[:merchantSig]
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
        :session_validity => Time.now + 3600 }

      @redirect_url = Adyen::Form.redirect_url(@attributes)
    end
    
    it "should return an URL pointing to the adyen server" do
      @redirect_url.should =~ %r[^#{Adyen::Form.url}]
    end
    
    it "should include all provided attributes" do
      params = @redirect_url.split('?', 2).last.split('&').map { |param| param.split('=', 2).first }
      params.should include(*(@attributes.keys.map { |k| Adyen::Form.camelize(k) }))
    end
    
    it "should include the merchant signature" do
      params = @redirect_url.split('?', 2).last.split('&').map { |param| param.split('=', 2).first }
      params.should include('merchantSig')
    end
  end

  describe 'hidden fields generation' do

    before(:each) do
      @attributes = { :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.today,
        :merchant_reference => 'Internet Order 12345', :skin => :testing,
        :session_validity => Time.now + 3600 }
    end

    it "should generate a valid payment form" do
      html_snippet = <<-HTML
        <form action="#{CGI.escapeHTML(Adyen::Form.url)}" method="post">#{Adyen::Form.hidden_fields(@attributes)}</form>
      HTML
      
      html_snippet.should have_adyen_payment_form
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
      signature_string.should == "10000GBP2007-10-20Internet Order 123454aD37dJATestMerchant2007-10-11T11:00:00Z"
    end
    
    it "should calculate the signature correctly" do
      signature = Adyen::Form.calculate_signature(@parameters)
      signature.should == 'x58ZcRVL1H6y+XSeBGrySJ9ACVo='
    end

    it "should calculate the signature correctly for a recurring payment" do
      # Add the required recurrent payment attributes
      @parameters.merge!(:recurring_contract => 'DEFAULT', :shopper_reference => 'grasshopper52', :shopper_email => 'gras.shopper@somewhere.org')

      signature_string = Adyen::Form.calculate_signature_string(@parameters)
      signature_string.should == "10000GBP2007-10-20Internet Order 123454aD37dJATestMerchant2007-10-11T11:00:00Zgras.shopper@somewhere.orggrasshopper52DEFAULT"
    end

    it "should calculate the signature correctly for a recurring payment" do
      # Add the required recurrent payment attributes
      @parameters.merge!(:recurring_contract => 'DEFAULT', :shopper_reference => 'grasshopper52', :shopper_email => 'gras.shopper@somewhere.org')

      signature = Adyen::Form.calculate_signature(@parameters)
      signature.should == 'F2BQEYbE+EUhiRGuPtcD16Gm7JY='
    end
  end
end

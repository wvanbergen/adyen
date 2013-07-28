# encoding: UTF-8

require 'date'
require 'spec_helper'
require 'adyen/form'

describe Adyen::Form do

  before(:each) do
    Adyen.configuration.register_form_skin(:testing, '4aD37dJA', 'Kah942*$7sdp0)')
    Adyen.configuration.default_form_params[:merchant_account] = 'TestMerchant'
  end

  describe 'Action URLs' do

    before(:each) do
      # Use autodetection for the environment unless otherwise specified
      Adyen.configuration.environment = nil
    end

    it "should generate correct testing url" do
      Adyen::Form.url.should == 'https://test.adyen.com/hpp/select.shtml'
    end

    it "should generate a live url if the environment is set to live" do
      Adyen.configuration.environment = :live
      Adyen::Form.url.should == 'https://live.adyen.com/hpp/select.shtml'
    end

    it "should generate correct live url in a production environment" do
      Adyen.configuration.stub(:autodetect_environment).and_return('live')
      Adyen::Form.url.should. == 'https://live.adyen.com/hpp/select.shtml'
    end

    it "should generate correct live url if explicitely asked for" do
      Adyen::Form.url(:live).should == 'https://live.adyen.com/hpp/select.shtml'
    end

    it "should generate correct testing url if the payment flow selection is set to select" do
      Adyen.configuration.payment_flow = :select
      Adyen::Form.url.should == 'https://test.adyen.com/hpp/select.shtml'
    end

    it "should generate correct testing url if the payment flow selection is set to pay" do
      Adyen.configuration.payment_flow = :pay
      Adyen::Form.url.should == 'https://test.adyen.com/hpp/pay.shtml'
    end

    it "should generate correct testing url if the payment flow selection is set to details" do
      Adyen.configuration.payment_flow = :details
      Adyen::Form.url.should == 'https://test.adyen.com/hpp/details.shtml'
    end

    context "with custom domain" do
      before(:each) do
        Adyen.configuration.payment_flow = :select
        Adyen.configuration.payment_flow_domain = "checkout.mydomain.com"
      end

      it "should generate correct testing url" do
        Adyen::Form.url.should == 'https://checkout.mydomain.com/hpp/select.shtml'
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
      params = @params.merge(:merchantReturnData => 'testing1234')
      Adyen::Form.redirect_signature_string(params).should == 'AUTHORISED1211992213193029Internet Order 123454aD37dJAtesting1234'
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

    it "should raise ArgumentError on missing skinCode" do
      expect do
        @params.delete(:skinCode)
        Adyen::Form.redirect_signature_check(@params).should be_false
      end.to raise_error ArgumentError
    end

    it "should raise ArgumentError on empty input" do
      expect do
        Adyen::Form.redirect_signature_check({}).should be_false
      end.to raise_error ArgumentError
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
    subject { %Q'<form action="#{CGI.escapeHTML(Adyen::Form.url)}" method="post">#{Adyen::Form.hidden_fields(@attributes)}</form>' }

    before(:each) do
      @attributes = { :currency_code => 'GBP', :payment_amount => 10000, :ship_before_date => Date.today,
        :merchant_reference => 'Internet Order 12345', :skin => :testing,
        :session_validity => Time.now + 3600 }
    end

    it { should have_adyen_payment_form }
    it { should include('<input type="hidden" name="merchantAccount" value="TestMerchant" />') }

    context "width default_form_params" do
      before(:each) do
        Adyen.configuration.register_form_skin(:testing, '4aD37dJA', 'Kah942*$7sdp0)', {
          :merchant_account => 'OtherMerchant',
        })
      end

      it { should include('<input type="hidden" name="merchantAccount" value="OtherMerchant" />') }
      it { should_not include('<input type="hidden" name="merchantAccount" value="TestMerchant" />') }
    end
  end

  describe 'signature calculation' do

    # This example is taken from the Adyen integration manual

    before(:each) do

      @parameters = { :currency_code => 'GBP', :payment_amount => 10000,
        :ship_before_date => '2007-10-20', :merchant_reference => 'Internet Order 12345',
        :skin => :testing, :session_validity => '2007-10-11T11:00:00Z',
        :billing_address => {
           :street               => 'Alexanderplatz',
           :house_number_or_name => '0815',
           :city                 => 'Berlin',
           :postal_code          => '10119',
           :state_or_province    => 'Berlin',
           :country              => 'Germany',
          }
        }

      Adyen::Form.do_parameter_transformations!(@parameters)
    end

    it "should construct the signature base string correctly" do
      signature_string = Adyen::Form.calculate_signature_string(@parameters)
      signature_string.should == "10000GBP2007-10-20Internet Order 123454aD37dJATestMerchant2007-10-11T11:00:00Z"

      signature_string = Adyen::Form.calculate_signature_string(@parameters.merge(:merchant_return_data => 'testing123'))
      signature_string.should == "10000GBP2007-10-20Internet Order 123454aD37dJATestMerchant2007-10-11T11:00:00Ztesting123"

    end

    it "should calculate the signature correctly" do
      signature = Adyen::Form.calculate_signature(@parameters)
      signature.should == 'x58ZcRVL1H6y+XSeBGrySJ9ACVo='
    end

    it "should raise ArgumentError on empty shared_secret" do
      expect do
        @parameters.delete(:shared_secret)
        signature = Adyen::Form.calculate_signature(@parameters)
      end.to raise_error ArgumentError
    end

    it "should calculate the signature base string correctly for a recurring payment" do
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

    context 'billing address' do

      it "should construct the signature base string correctly" do
        signature_string = Adyen::Form.calculate_billing_address_signature_string(@parameters[:billing_address])
        signature_string.should == "Alexanderplatz0815Berlin10119BerlinGermany"
      end

      it "should calculate the signature correctly" do
        signature = Adyen::Form.calculate_billing_address_signature(@parameters)
        signature.should == '5KQb7VJq4cz75cqp11JDajntCY4='
      end

      it "should raise ArgumentError on empty shared_secret" do
        expect do
          @parameters.delete(:shared_secret)
          signature = Adyen::Form.calculate_billing_address_signature(@parameters)
        end.to raise_error ArgumentError
      end
    end

  end

  describe "flatten" do
   let(:parameters) do
      {
        :billing_address => { :street => 'My Street'}
      }
    end

    it "returns empty hash for nil input" do
      Adyen::Form.flatten(nil).should == {}
    end

    it "flattens hash and prefixes keys" do
      Adyen::Form.flatten(parameters).should == {
        'billingAddress.street' =>  'My Street'
      }
    end
  end
end

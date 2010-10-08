require File.expand_path("../spec_helper", __FILE__)

describe Adyen::API::RecurringService do
  include APISpecHelper

  before do
    @params = { :shopper => { :reference => 'user-id' } }
    @recurring = @object = Adyen::API::RecurringService.new(@params)
  end

  describe "list_request_body" do
    before :all do
      @method = :list_request_body
    end

    it "includes the merchant account handle" do
      text('./recurring:merchantAccount').should == 'SuperShopper'
    end

    it "includes the shopper’s reference" do
      text('./recurring:shopperReference').should == 'user-id'
    end

    it "includes the type of contract, which is always `RECURRING'" do
      text('./recurring:recurring/recurring:contract').should == 'RECURRING'
    end

    private

    def node_for_current_method
      node_for_current_object_and_method.xpath('//recurring:listRecurringDetails/recurring:request')
    end
  end

  describe "list" do
    before do
      stub_net_http(LIST_RESPONSE)
      @response = @recurring.list
      @request, @post = Net::HTTP.posted
    end

    after do
      Net::HTTP.stubbing_enabled = false
    end

    it "posts the body generated for the given parameters" do
      @post.body.should == @recurring.list_request_body
    end

    it "posts to the correct SOAP action" do
      @post.soap_action.should == 'listRecurringDetails'
    end

    for_each_xml_backend do
      it "returns a hash with parsed response details" do
        @recurring.list.params.should == {
          :creation_date => DateTime.parse('2009-10-27T11:26:22.203+01:00'),
          :last_known_shopper_email => 's.hopper@example.com',
          :shopper_reference => 'user-id',
          :details => [
            {
              :card => {
                :expiry_date => Date.new(2012, 12, 31),
                :holder_name => 'S. Hopper',
                :number => '1111'
              },
              :recurring_detail_reference => 'RecurringDetailReference1',
              :variant => 'mc',
              :creation_date => DateTime.parse('2009-10-27T11:50:12.178+01:00')
            },
            {
              :bank => {
                :bank_account_number => '123456789',
                :bank_location_id => 'bank-location-id',
                :bank_name => 'AnyBank',
                :bic => 'BBBBCCLLbbb',
                :country_code => 'NL',
                :iban => 'NL69PSTB0001234567',
                :owner_name => 'S. Hopper'
              },
              :recurring_detail_reference => 'RecurringDetailReference2',
              :variant => 'IDEAL',
              :creation_date => DateTime.parse('2009-10-27T11:26:22.216+01:00')
            },
          ],
        }
      end

      it_should_have_shortcut_methods_for_params_on_the_response

      it "returns an empty hash when there are no details" do
        stub_net_http(LIST_EMPTY_RESPONSE)
        @recurring.list.params.should == {}
      end
    end

    describe "disable_request_body" do
      before :all do
        @method = :disable_request_body
      end

      it "includes the merchant account handle" do
        text('./recurring:merchantAccount').should == 'SuperShopper'
      end

      it "includes the shopper’s reference" do
        text('./recurring:shopperReference').should == 'user-id'
      end

      it "includes the shopper’s recurring detail reference if it is given" do
        xpath('./recurring:recurringDetailReference').should be_empty
        @recurring.params[:recurring_detail_reference] = 'RecurringDetailReference1'
        text('./recurring:recurringDetailReference').should == 'RecurringDetailReference1'
      end

      private

      def node_for_current_method
        node_for_current_object_and_method.xpath('//recurring:disable/recurring:request')
      end
    end

    describe "disable" do
      before do
        stub_net_http(DISABLE_RESPONSE % '[detail-successfully-disabled]')
        @response = @recurring.disable
        @request, @post = Net::HTTP.posted
      end

      after do
        Net::HTTP.stubbing_enabled = false
      end

      it "posts the body generated for the given parameters" do
        @post.body.should == @recurring.disable_request_body
      end

      it "posts to the correct SOAP action" do
        @post.soap_action.should == 'disable'
      end

      it "returns whether or not it was disabled" do
        @response.should be_success
        @response.should be_disabled

        stub_net_http(DISABLE_RESPONSE % '[all-details-successfully-disabled]')
        @response = @recurring.disable
        @response.should be_success
        @response.should be_disabled
      end

      for_each_xml_backend do
        it "returns a hash with parsed response details" do
          @recurring.disable.params.should == { :response => '[detail-successfully-disabled]' }
        end
      end

      it_should_have_shortcut_methods_for_params_on_the_response
    end
  end

  describe "test helpers that stub responses" do
    after do
      Net::HTTP.stubbing_enabled = false
    end

    it "returns a `disabled' response" do
      stub_net_http(DISABLE_RESPONSE % 'nope')
      Adyen::API::RecurringService.stub_disabled!
      @recurring.disable.should be_disabled
      @recurring.disable.should_not be_disabled
    end
  end
end

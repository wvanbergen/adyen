# encoding: UTF-8
require 'api/spec_helper'
require 'date'

describe Adyen::API::RecurringService do
  include APISpecHelper

  before do
    @params = { :shopper => { :reference => 'user-id' } }
    @recurring = @object = Adyen::API::RecurringService.new(@params)
  end

  describe_request_body_of :list, '//recurring:listRecurringDetails/recurring:request' do
    it_should_validate_request_parameters :merchant_account,
                                          :shopper => [:reference]

    it "includes the merchant account handle" do
      text('./recurring:merchantAccount').should == 'SuperShopper'
    end

    it "includes the shopper’s reference" do
      text('./recurring:shopperReference').should == 'user-id'
    end

    it "includes the type of contract, which is always `RECURRING'" do
      text('./recurring:recurring/recurring:contract').should == 'RECURRING'
    end
  end

  describe_response_from :list, LIST_RESPONSE, 'listRecurringDetails' do
    it_should_return_params_for_each_xml_backend({
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
    })

    it "returns an array with just the detail references" do
      @response.references.should == %w{ RecurringDetailReference1 RecurringDetailReference2 }
    end

    it "returns an empty hash when there are no details" do
      stub_net_http(LIST_EMPTY_RESPONSE)
      @recurring.list.params.should == {}
    end
  end

  describe_request_body_of :disable, '//recurring:disable/recurring:request' do
    it_should_validate_request_parameters :merchant_account,
                                          :shopper => [:reference]

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
  end

  describe_response_from :disable, (DISABLE_RESPONSE % '[detail-successfully-disabled]'), 'disable' do
    it "returns whether or not it was disabled" do
      @response.should be_success
      @response.should be_disabled

      stub_net_http(DISABLE_RESPONSE % '[all-details-successfully-disabled]')
      @response = @recurring.disable
      @response.should be_success
      @response.should be_disabled
    end

    it_should_return_params_for_each_xml_backend(:response => '[detail-successfully-disabled]')
  end
end

# encoding: UTF-8
require 'api/spec_helper'

shared_examples_for "payout requests" do
  it "includes the merchant account handle" do
    text('./payout:merchantAccount').should == 'SuperShopper'
  end

  it "includes the bank details" do
    xpath('./payout:bank') do |bank|
      bank.text('./payment:iban').should == 'NL48RABO0132394782'
      bank.text('./payment:bic').should == 'RABONL2U'
      bank.text('./payment:bankName').should == 'Rabobank'
      bank.text('./payment:countryCode').should == 'NL'
      bank.text('./payment:ownerName').should == 'Test Shopper'
    end
  end

  it "includes the shopper’s details" do
    text('./payout:shopperReference').should == 'user-id'
    text('./payout:shopperEmail').should == 's.hopper@example.com'
  end
end

describe Adyen::API::PayoutService do
  include APISpecHelper

  before do
    @params = {
      :shopper => {
        :email => 's.hopper@example.com',
        :reference => 'user-id'
      },
      :bank => {
        :iban => "NL48RABO0132394782",
        :bic => "RABONL2U",
        :bank_name => 'Rabobank',
        :country_code => 'NL',
        :owner_name => 'Test Shopper'
      }
    }
    @payout = @object = Adyen::API::PayoutService.new(@params)
  end

  describe_request_body_of :store_detail do
    it_should_behave_like "payout requests"

    it_should_validate_request_parameters :merchant_account,
                                          :shopper => [:reference, :email],
                                          :bank => [:iban, :bic, :bank_name, :country_code, :owner_name]

    it_should_validate_request_param(:shopper) do
      @payout.params[:shopper] = nil
    end

    [:reference, :email].each do |attr|
      it_should_validate_request_param(:shopper) do
        @payout.params[:shopper][attr] = ''
      end
    end

    it "includes the necessary recurring contract info" do
      text('./payout:recurring/payment:contract').should == 'PAYOUT'
    end
  end

  describe_response_from :store_detail, STORE_DETAIL_RESPONSE, 'storeDetail' do
    it_should_return_params_for_each_xml_backend({
      :psp_reference => '9913134957760023',
      :result_code => 'Success',
      :recurring_detail_reference => '2713134957760046'
    })
  end

  private

  def node_for_current_method
    node_for_current_object_and_method.xpath('//payout:storeDetail/payout:request')
  end
end

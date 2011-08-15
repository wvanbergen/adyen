# encoding: UTF-8
require 'api/spec_helper'

describe Adyen::API::ElvPaymentService do
  include APISpecHelper

  before do
    @params = {
      :reference => 'order-id',
      :amount => {
        :currency => 'EUR',
        :value => '1234',
      },
      :shopper => {
        :email => 's.hopper@example.com',
        :reference => 'user-id',
        :ip => '61.294.12.12',
      },
      :elv => {
        :holder_name => 'Simon Hopper',
        :number => '1234567890',
        :bank_location_id => '12345678'
      }
    }
    @payment = @object = Adyen::API::ElvPaymentService.new(@params)
  end

  describe_request_body_of :authorise_payment do
    it_should_validate_request_parameters :elv => [:holder_name, :number, :bank_location_id]

    it "includes the elv details" do
      xpath('./payment:elv') do |elv|
        elv.text('./payment:accountHolderName').should == 'Simon Hopper'
        elv.text('./payment:bankAccountNumber').should == '1234567890'
        elv.text('./payment:bankLocationId').should == '12345678'
      end
    end
  end

  private

  def node_for_current_method
    node_for_current_object_and_method.xpath('//payment:authorise/payment:paymentRequest')
  end
end

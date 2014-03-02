# encoding: UTF-8
require 'api/spec_helper'

describe Adyen::API do
  include APISpecHelper

  describe "shortcut methods" do
    describe "for the PaymentService" do
      before do
        @payment = double('PaymentService')
      end

      def should_map_shortcut_to(method, params)
        Adyen::API::PaymentService.should_receive(:new).with(params).and_return(@payment)
        @payment.should_receive(method)
      end

      it "performs a `authorise payment' request without enabling :recurring" do
        should_map_shortcut_to(:authorise_payment,
          :reference => 'order-id',
          :amount => { :currency => 'EUR', :value => 1234 },
          :shopper => { :reference => 'user-id', :email => 's.hopper@example.com' },
          :card => { :expiry_month => 12, :expiry_year => 2012, :holder_name => "Simon Hopper", :number => '4444333322221111', :cvc => '737' },
          :recurring => false,
          :fraud_offset => nil
        )
        Adyen::API.authorise_payment('order-id',
          { :currency => 'EUR', :value => 1234 },
          { :reference => 'user-id', :email => 's.hopper@example.com' },
          { :expiry_month => 12, :expiry_year => 2012, :holder_name => "Simon Hopper", :number => '4444333322221111', :cvc => '737' }
        )
      end

      it "performs a `authorise payment' request with additional :fraud_offset" do
        should_map_shortcut_to(:authorise_payment,
          :reference => 'order-id',
          :amount => { :currency => 'EUR', :value => 1234 },
          :shopper => { :reference => 'user-id', :email => 's.hopper@example.com' },
          :card => { :expiry_month => 12, :expiry_year => 2012, :holder_name => "Simon Hopper", :number => '4444333322221111', :cvc => '737' },
          :recurring => false,
          :fraud_offset => -100
        )
        Adyen::API.authorise_payment('order-id',
          { :currency => 'EUR', :value => 1234 },
          { :reference => 'user-id', :email => 's.hopper@example.com' },
          { :expiry_month => 12, :expiry_year => 2012, :holder_name => "Simon Hopper", :number => '4444333322221111', :cvc => '737' },
          false,
          -100
        )
      end

      it "performs a `authorise payment' request with enabling :recurring" do
        should_map_shortcut_to(:authorise_payment,
          :reference => 'order-id',
          :amount => { :currency => 'EUR', :value => 1234 },
          :shopper => { :reference => 'user-id', :email => 's.hopper@example.com' },
          :card => { :expiry_month => 12, :expiry_year => 2012, :holder_name => "Simon Hopper", :number => '4444333322221111', :cvc => '737' },
          :recurring => true,
          :fraud_offset => nil
        )
        Adyen::API.authorise_payment('order-id',
          { :currency => 'EUR', :value => 1234 },
          { :reference => 'user-id', :email => 's.hopper@example.com' },
          { :expiry_month => 12, :expiry_year => 2012, :holder_name => "Simon Hopper", :number => '4444333322221111', :cvc => '737' },
          true
        )
      end

      it "performs a `authorise recurring payment' request without specific detail" do
        should_map_shortcut_to(:authorise_recurring_payment,
          :reference => 'order-id',
          :amount => { :currency => 'EUR', :value => 1234 },
          :shopper => { :reference => 'user-id', :email => 's.hopper@example.com' },
          :recurring_detail_reference => 'LATEST',
          :fraud_offset => nil
        )
        Adyen::API.authorise_recurring_payment('order-id',
          { :currency => 'EUR', :value => 1234 },
          { :reference => 'user-id', :email => 's.hopper@example.com' }
        )
      end

      it "performs a `authorise recurring payment' request with specific detail" do
        should_map_shortcut_to(:authorise_recurring_payment,
          :reference => 'order-id',
          :amount => { :currency => 'EUR', :value => 1234 },
          :shopper => { :reference => 'user-id', :email => 's.hopper@example.com' },
          :recurring_detail_reference => 'recurring-detail-reference',
          :fraud_offset => nil
        )
        Adyen::API.authorise_recurring_payment('order-id',
          { :currency => 'EUR', :value => 1234 },
          { :reference => 'user-id', :email => 's.hopper@example.com' },
          'recurring-detail-reference'
        )
      end

      it "performs a `authorise recurring payment' request with specific detail and fraud offset" do
        should_map_shortcut_to(:authorise_recurring_payment,
          :reference => 'order-id',
          :amount => { :currency => 'EUR', :value => 1234 },
          :shopper => { :reference => 'user-id', :email => 's.hopper@example.com' },
          :recurring_detail_reference => 'recurring-detail-reference',
          :fraud_offset => 50
        )
        Adyen::API.authorise_recurring_payment('order-id',
          { :currency => 'EUR', :value => 1234 },
          { :reference => 'user-id', :email => 's.hopper@example.com' },
          'recurring-detail-reference',
          50
        )
      end

      it "performs a `authorise one-click payment' request with specific detail" do
        should_map_shortcut_to(:authorise_one_click_payment,
          :reference => 'order-id',
          :amount => { :currency => 'EUR', :value => 1234 },
          :shopper => { :reference => 'user-id', :email => 's.hopper@example.com' },
          :card => { :cvc => '737' },
          :recurring_detail_reference => 'recurring-detail-reference',
          :fraud_offset => nil
        )
        Adyen::API.authorise_one_click_payment('order-id',
          { :currency => 'EUR', :value => 1234 },
          { :reference => 'user-id', :email => 's.hopper@example.com' },
          '737',
          'recurring-detail-reference'
        )
      end

      it "performs a `authorise one-click payment' request with specific detail and fraud offset" do
        should_map_shortcut_to(:authorise_one_click_payment,
          :reference => 'order-id',
          :amount => { :currency => 'EUR', :value => 1234 },
          :shopper => { :reference => 'user-id', :email => 's.hopper@example.com' },
          :card => { :cvc => '737' },
          :recurring_detail_reference => 'recurring-detail-reference',
          :fraud_offset => -10
        )
        Adyen::API.authorise_one_click_payment('order-id',
          { :currency => 'EUR', :value => 1234 },
          { :reference => 'user-id', :email => 's.hopper@example.com' },
          '737',
          'recurring-detail-reference',
          -10
        )
      end

      it "performs a `capture' request" do
        should_map_shortcut_to(:capture, :psp_reference => 'original-psp-reference', :amount => { :currency => 'EUR', :value => '1234' })
        Adyen::API.capture_payment('original-psp-reference', { :currency => 'EUR', :value => '1234' })
      end

      it "performs a `refund payment' request" do
        should_map_shortcut_to(:refund, :psp_reference => 'original-psp-reference', :amount => { :currency => 'EUR', :value => '1234' })
        Adyen::API.refund_payment('original-psp-reference', { :currency => 'EUR', :value => '1234' })
      end

      it "performs a `cancel or refund payment' request" do
        should_map_shortcut_to(:cancel_or_refund, :psp_reference => 'original-psp-reference')
        Adyen::API.cancel_or_refund_payment('original-psp-reference')
      end

      it "performs a `cancel payment' request" do
        should_map_shortcut_to(:cancel, :psp_reference => 'original-psp-reference')
        Adyen::API.cancel_payment('original-psp-reference')
      end
    end

    describe "for the RecurringService" do
      before do
        @recurring = double('RecurringService')
      end

      def should_map_shortcut_to(method, params)
        Adyen::API::RecurringService.should_receive(:new).with(params).and_return(@recurring)
        @recurring.should_receive(method)
      end

      it "performs a `tokenize creditcard details' request" do
        should_map_shortcut_to(:store_token,
          :shopper => { :reference => 'user-id', :email => 's.hopper@example.com' },
          :card => { :expiry_month => 12, :expiry_year => 2012, :holder_name => "Simon Hopper", :number => '4444333322221111' }
        )
        Adyen::API.store_recurring_token(
          { :reference => 'user-id', :email => 's.hopper@example.com' },
          { :expiry_month => 12, :expiry_year => 2012, :holder_name => "Simon Hopper", :number => '4444333322221111' }
        )
      end

      it "performs a `tokenize ELV details' request" do
        should_map_shortcut_to(:store_token,
          :shopper => { :reference => 'user-id', :email => 's.hopper@example.com' },
          :elv => { :bank_location => "Berlin", :bank_name => "TestBank", :bank_location_id => "12345678", :holder_name => "Simon Hopper", :number => "1234567890" }
        )
        Adyen::API.store_recurring_token(
          { :reference => 'user-id', :email => 's.hopper@example.com' },
          { :bank_location => "Berlin", :bank_name => "TestBank", :bank_location_id => "12345678", :holder_name => "Simon Hopper", :number => "1234567890" }
        )
      end

      it "preforms a `list recurring details' request" do
        should_map_shortcut_to(:list, :shopper => { :reference => 'user-id' })
        Adyen::API.list_recurring_details('user-id')
      end

      it "performs a `disable recurring contract' request for all details" do
        should_map_shortcut_to(:disable, :shopper => { :reference => 'user-id' }, :recurring_detail_reference => nil)
        Adyen::API.disable_recurring_contract('user-id')
      end

      it "performs a `disable recurring contract' request for a specific detail" do
        should_map_shortcut_to(:disable, :shopper => { :reference => 'user-id' }, :recurring_detail_reference => 'detail-id')
        Adyen::API.disable_recurring_contract('user-id', 'detail-id')
      end
    end
  end
end

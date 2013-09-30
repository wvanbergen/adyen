require 'spec_helper'

describe AdyenNotification, 'when logging a valid notification' do
  before :each do
    @event_date = DateTime.now
    @psp_ref = generate(:psp_reference)
    @notification = AdyenNotification.log({
      psp_reference: @psp_ref,
      event_code: 'AUTHORISATION',
      merchant_reference: 'transaction_code',
      merchant_account_code: 'test_account',
      event_date: @event_date,
      success: true
    })
  end

  it 'will save the psp reference' do @notification.psp_reference.should == @psp_ref end
  it 'will save the event code' do @notification.event_code.should == 'AUTHORISATION' end
  it 'will save the merchant reference' do @notification.merchant_reference.should == 'transaction_code' end
  it 'will save the merchant account code' do @notification.merchant_account_code.should == 'test_account' end
  it 'will save the event date' do @notification.event_date.should == @event_date end
end

describe AdyenNotification, 'when the merchant reference is missing' do
  it 'will raise the expected error' do
    expect { AdyenNotification.log({
         psp_reference: generate(:psp_reference),
         event_code: 'AUTHORISATION',
         merchant_account_code: 'upmysport_test',
         event_date: @event_date
       })
    }.to raise_error ActiveRecord::RecordInvalid
  end
end

describe AdyenNotification, 'when the event code is missing' do
  it 'will raise the expected error' do
    expect do
      AdyenNotification.log({
         psp_reference: generate(:psp_reference),
         merchant_reference: 'booking_code',
         merchant_account_code: 'upmysport_test',
         event_date: @event_date
       })
    end.to raise_error ActiveRecord::RecordInvalid
  end
end

describe AdyenNotification, 'when the psp reference is missing' do
  it 'will raise the expected error' do
    expect do
      AdyenNotification.log({
        event_code: 'AUTHORISATION',
        merchant_reference: 'booking_code',
        merchant_account_code: 'upmysport_test',
        event_date: @event_date
      })
    end.to raise_error ActiveRecord::RecordInvalid
  end
end
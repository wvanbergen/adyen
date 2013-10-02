require 'spec_helper'

module NotificationTestHelper
  def fake_notification
    {
        psp_reference: generate(:psp_reference),
        event_code: 'AUTHORISATION',
        merchant_reference: 'transaction_code',
        merchant_account_code: 'test_account',
        event_date: @event_date,
        success: true
    }
  end

  def notification_without param_name
    note = fake_notification
    note.delete param_name.to_sym
    return note
  end
end

describe AdyenNotification, 'when logging a valid notification' do
  include NotificationTestHelper
  before :each do
    @event_date = DateTime.now
    note = fake_notification
    @psp_ref = note[:psp_reference]
    @notification = AdyenNotification.log(note)
  end

  it 'will save the psp reference' do @notification.psp_reference.should == @psp_ref end
  it 'will save the event code' do @notification.event_code.should == 'AUTHORISATION' end
  it 'will save the merchant reference' do @notification.merchant_reference.should == 'transaction_code' end
  it 'will save the merchant account code' do @notification.merchant_account_code.should == 'test_account' end
  it 'will save the event date' do @notification.event_date.should == @event_date end
end

describe AdyenNotification, 'when the merchant reference is missing' do
  include NotificationTestHelper
  it 'will raise the expected error' do
    expect {AdyenNotification.log(notification_without(:merchant_reference))}.to raise_error ActiveRecord::RecordInvalid
  end
end

describe AdyenNotification, 'when the event code is missing' do
  include NotificationTestHelper
  it 'will raise the expected error' do
    expect {AdyenNotification.log(notification_without(:event_code))}.to raise_error ActiveRecord::RecordInvalid
  end
end

describe AdyenNotification, 'when the psp reference is missing' do
  include NotificationTestHelper
  it 'will raise the expected error' do
    expect {AdyenNotification.log(notification_without(:psp_reference))}.to raise_error ActiveRecord::RecordInvalid
  end
end

describe AdyenNotification, 'when the merchant account code is missing' do
  include NotificationTestHelper
  it 'will raise the expected error' do
    expect {AdyenNotification.log(notification_without(:merchant_account_code))}.to raise_error ActiveRecord::RecordInvalid
  end
end


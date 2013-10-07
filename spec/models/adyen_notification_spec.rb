require 'spec_helper'

module NotificationTestHelper
  def fake_notification
    @event_date = DateTime.now
    @psp_ref = generate(:psp_reference)
    {
        'event_code' => 'AUTHORISATION',
        'event_date' => @event_date,
        'merchant_reference' => 'transaction_code',
        'merchant_account_code' => 'test_account',
        'psp_reference' => @psp_ref,
        'success' => 'true'
    }
  end

  def notification_without(param_name)
    note = fake_notification
    note.delete param_name.to_s
    return note
  end
end

describe AdyenNotification, 'when logging a valid notification' do
  include NotificationTestHelper
  before :each do
    note = fake_notification
    @notification = AdyenNotification.log(note)
  end

  it 'will save the psp reference' do expect(@notification.psp_reference).to eq(@psp_ref) end
  it 'will save the event code' do expect(@notification.event_code).to eq('AUTHORISATION') end
  it 'will save the merchant reference' do expect(@notification.merchant_reference).to eq('transaction_code') end
  it 'will save the merchant account code' do expect(@notification.merchant_account_code).to eq('test_account') end
  # beware of failures here, they could be caused by the test database not being reset
  it 'will save the event date' do expect(@notification.event_date.utc).to eq(@event_date.utc) end
end

describe AdyenNotification, 'when a successful notification is logged twice for the same transaction' do
  include NotificationTestHelper

  before :each do
    note = fake_notification
    @notification = AdyenNotification.log(note)
    @duplicate = AdyenNotification.log(note)
  end

  it 'will save the first notification' do expect(@notification).not_to be_nil end
  it 'will return the duplicate notification' do expect(@duplicate).not_to be_nil end
  it 'will return the same object from both log calls' do expect(@notification.id).to eq(@duplicate.id) end
end

describe AdyenNotification, 'when a failure notification is followed by a successful notification for the same transaction' do
  include NotificationTestHelper

  before :each do
    note = fake_notification
    note['success'] = false
    @notification = AdyenNotification.log(note)
    note['success'] = true
    @duplicate = AdyenNotification.log(note)
  end

  it 'will save the first notification' do expect(@notification).not_to be_nil end
  it 'will return the duplicate notification' do expect(@duplicate).not_to be_nil end
  it 'will not return the same object from both log calls' do expect(@notification.id).not_to eq(@duplicate.id) end
end

describe AdyenNotification, 'when the event code is missing' do
  include NotificationTestHelper
  it 'will raise the expected error' do
    expect {AdyenNotification.log(notification_without(:event_code))}.to raise_error ActiveRecord::RecordInvalid
  end
end

describe AdyenNotification, 'when the event date is missing' do
  include NotificationTestHelper
  it 'will raise the expected error' do
    expect {AdyenNotification.log(notification_without(:event_date))}.to raise_error ActiveRecord::RecordInvalid
  end
end

describe AdyenNotification, 'when the merchant account code is missing' do
  include NotificationTestHelper
  it 'will raise the expected error' do
    expect {AdyenNotification.log(notification_without(:merchant_account_code))}.to raise_error ActiveRecord::RecordInvalid
  end
end

describe AdyenNotification, 'when the merchant reference is missing' do
  include NotificationTestHelper
  it 'will raise the expected error' do
    expect {AdyenNotification.log(notification_without(:merchant_reference))}.to raise_error ActiveRecord::RecordInvalid
  end
end

describe AdyenNotification, 'when the psp reference is missing' do
  include NotificationTestHelper
  it 'will raise the expected error' do
    expect {AdyenNotification.log(notification_without(:psp_reference))}.to raise_error ActiveRecord::RecordInvalid
  end
end

describe AdyenNotification, 'when decorated with a hook' do
  include NotificationTestHelper

  before :all do
    AdyenNotification.class_eval do
      def hook!
        instance_eval do
          def hooked?
            true
          end
        end
      end
    end

    @notification = AdyenNotification.log(fake_notification)
  end

  it 'will execute the hook' do
    expect(@notification.hooked?).to be_true
  end
end

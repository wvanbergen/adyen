class Adyen::NotificationsController < Adyen::ApplicationController
  before_filter :authenticate

  def notify
    @notification = AdyenNotification.log(params)
    render text: '[accepted]'
  end

  private
  def authenticate
    authenticate_or_request_with_http_basic do |username, password|
      username == 'changeme' && password == 'iamnotsecure'
    end
  end
end

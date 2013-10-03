class Adyen::NotificationsController < Adyen::ApplicationController
  before_filter :authenticate

  def notify
    Rails.logger.info "Received Adyen notification:\n    #{params}"
    begin
      @notification = AdyenNotification.log(params)
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn "Unable to log Adyen notification:\n#{e}"
      Rails.logger.warn "    #{e.backtrace.join("    \n")}"
    end
    render text: '[accepted]'
  end

  private
  def authenticate
    unless Adyen.config.disable_basic_auth
      authenticate_or_request_with_http_basic do |username, password|
        username == Adyen.config.http_username && password == Adyen.config.http_password
      end
    end
  end
end

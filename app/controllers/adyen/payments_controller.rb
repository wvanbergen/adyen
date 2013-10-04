class Adyen::PaymentsController < Adyen::ApplicationController
  def result
    Rails.logger.info "Received payment result, params: #{params}"

  end
end
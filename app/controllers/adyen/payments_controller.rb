class Adyen::PaymentsController < Adyen::ApplicationController
  before_filter :check_signature, only: :result

  def result
    Rails.logger.info "Received payment result, params: #{params}"
    redirect_to Adyen.config.payment_result_redirect.call(self)
  end

  def complete

  end

  def check_signature
    raise Adyen::InvalidSignature.new('Forgery!') unless Adyen::Signature.redirect_signature_check(params)
  end
end
class Adyen::PaymentsController < Adyen::ApplicationController
  before_filter :check_signature

  def result
    Rails.logger.info "Received payment result, params: #{params}"
  end

  def check_signature
    raise Adyen::InvalidSignature.new('Forgery!') unless Adyen::Signature.redirect_signature_check(params)
  end
end
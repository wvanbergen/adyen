class Adyen::PaymentsController < Adyen::ApplicationController
  before_filter :check_signature, only: :result

  def result
    Rails.logger.info "Received payment result, params: #{params}"
    redirect_to Adyen.config.payment_result_redirect.call(self)
  end

  def complete
    Rails.logger.warn 'You are using the default Adyen payment complete page.  '+
        'The page looks pretty terrible, so please take the time to implement the'+
        ' payment_result_redirect coniguration in the Adyen engine.'
  end

  def check_signature
    raise Adyen::InvalidSignature.new('Forgery!') unless Adyen::Signature.redirect_signature_check(params)
  end

  def payment_success?
    params[:authResult] == 'AUTHORISATION'
  end

  def merchant_reference
    params[:merchantReference]
  end
end
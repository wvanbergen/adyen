class Adyen::PaymentsController < Adyen::ApplicationController
  before_filter :create_signature
  before_filter :check_signature, only: :result

  def result
    Rails.logger.info "Received payment result, params: #{params}"
    redirect_to Adyen.config.payment_result_redirect(self)
  end

  def complete
    Rails.logger.warn 'You are using the default Adyen payment complete page.  '+
        'The page looks pretty terrible, so please take the time to implement the'+
        ' payment_result_redirect coniguration in the Adyen engine.'
  end

  def create_signature
    adyen_params = params.clone
    adyen_params.delete(:action)
    adyen_params.delete(:controller)
    @signature = Adyen::PaymentResult.new(adyen_params)
  end

  def check_signature
    raise Adyen::InvalidSignature.new('Forgery!') unless @signature.has_valid_signature?
  end

  def payment_success?
    @signature.payment_success?
  end

  def merchant_reference
    params[:merchantReference]
  end
end
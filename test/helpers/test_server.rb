require 'sinatra'

class Adyen::TestServer < Sinatra::Base
  set :views, File.join(File.dirname(__FILE__), 'views')

  def adyen_client
    @adyen_client ||= begin
      setup_api_configuration
      Adyen::REST.client
    end
  end

  get '/' do
    erb :index
  end

  get '/pay' do
    erb :pay
  end

  post '/pay' do
    response = adyen_client.api_request('Payment.authorise', 
      payment_request: {
        merchant_account: 'VanBergenORG',
        amount: { currency: 'EUR', value: 1234 },
        reference: 'Test order #1',
        card: params[:card],
        browser_info: {
          acceptHeader: request['Accept'] || "text/html;q=0.9,*/*",
          userAgent: request.user_agent
        }
      }
    )

    @psp_reference = response['payment_result']['psp_reference']

    if response['payment_result']['result_code'] == 'RedirectShopper'
      @term_url   = request.url.sub(%r{/pay\z}, '/3dsecure/return')
      @issuer_url = response['payment_result']['issuer_url']
      @md         = response['payment_result']['md']
      @pa_request = response['payment_result']['pa_request']

      erb :redirect_shopper

    elsif response['payment_result']['result_code'] == 'Authorised'
      erb :authorized

    else
      status 400
      body response['payment_result']['refusal_reason']
    end
  end

  get '/capture/:psp_reference' do
    @psp_reference = params[:psp_reference]
    erb :capture
  end

  post '/capture' do
    response = adyen_client.api_request('Payment.capture', modification_request: {
      merchant_account: 'VanBergenORG',
      original_reference: params[:psp_reference],
      modification_amount: {
        currency: 'EUR',
        value: params[:value]
      }
    })

    if response['modification_result']['response'] == '[capture-received]'
      body "Capture received (PSP reference: #{response['modification_result']['psp_reference']})"
    else
      status 400
      body response['modification_result']['response']
    end
  end

  get '/cancel/:psp_reference' do
    @psp_reference = params[:psp_reference]
    erb :cancel
  end

  post '/cancel' do
    response = adyen_client.api_request('Payment.cancel', modification_request: {
      merchant_account: 'VanBergenORG',
      original_reference: params[:psp_reference],
    })

    if response['modification_result']['response'] == '[cancel-received]'
      body "Cancel received (PSP reference: #{response['modification_result']['psp_reference']})"
    else
      status 400
      body response['modification_result']['response']
    end
  end

  get '/refund/:psp_reference' do
    @psp_reference = params[:psp_reference]
    erb :refund
  end

  post '/refund' do
    response = adyen_client.api_request('Payment.refund', modification_request: {
      merchant_account: 'VanBergenORG',
      original_reference: params[:psp_reference],
      modification_amount: {
        currency: 'EUR',
        value: params[:value]
      }
    })

    if response['modification_result']['response'] == '[refund-received]'
      body "Refund received (PSP reference: #{response['modification_result']['psp_reference']})"
    else
      status 400
      body response['modification_result']['response']
    end
  end

  get '/refundorcancel/:psp_reference' do
    @psp_reference = params[:psp_reference]
    erb :refundorcancel
  end

  post '/refundorcancel' do
    response = adyen_client.api_request('Payment.cancelOrRefund', modification_request: {
      merchant_account: 'VanBergenORG',
      original_reference: params[:psp_reference],
    })

    if response['modification_result']['response'] == '[cancelOrRefund-received]'
      body "CancelOrRefund received (PSP reference: #{response['modification_result']['psp_reference']})"
    else
      status 400
      body response['modification_result']['response']
    end
  end    

  post '/3dsecure/return' do
    p params
    erb :success
  end
end

require 'sinatra'

class Adyen::TestServer < Sinatra::Base
  set :views,         File.join(File.dirname(__FILE__), 'views')
  set :public_folder, File.join(File.dirname(__FILE__), 'public')

  def initialize
    super
    setup_api_configuration
  end

  get '/' do
    erb :index
  end

  get '/pay' do
    erb :pay
  end

  post '/pay' do
    response = Adyen::REST.client.api_request('Payment.authorise', 
      payment_request: {
        merchant_account: 'VanBergenORG',
        amount: { currency: 'EUR', value: 1234 },
        reference: 'Test order #1',
        browser_info: {
          acceptHeader: request['Accept'] || "text/html;q=0.9,*/*",
          userAgent: request.user_agent
        },
        additionalData: {
          card: {
            encrypted: {
              json: params['adyen-encrypted-data']
            }
          }
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

  post '/3dsecure/return' do
    raise "still to do"
  end
end

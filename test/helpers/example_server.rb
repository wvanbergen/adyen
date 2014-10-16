require 'sinatra'

class Adyen::ExampleServer < Sinatra::Base
  set :views,         File.join(File.dirname(__FILE__), 'views')
  set :public_folder, File.join(File.dirname(__FILE__), 'public')

  def initialize
    super
    setup_api_configuration
  end

  get '/' do
    erb :index
  end

  get '/hpp' do
   @payment = {
      :skin => :testing,
      :currency_code => 'EUR',
      :payment_amount => 4321,
      :merchant_reference => params[:merchant_reference] || 'HPP test order',
      :ship_before_date => (Date.today + 1).strftime('%F'),
      :session_validity => (Time.now.utc + 30*60).strftime('%FT%TZ'),
      :billing_address => {
        :street               => 'Alexanderplatz',
        :house_number_or_name => '0815',
        :city                 => 'Berlin',
        :postal_code          => '10119',
        :state_or_province    => 'Berlin',
        :country              => 'Germany',
      },
      :shopper => {
        :telephone_number       => '123-4512-345',
        :first_name             => 'John',
        :last_name              => 'Doe',
      }
    }

    erb :hpp
  end

  get '/hpp/result' do
    raise "Forgery!" unless Adyen::Form.redirect_signature_check(params)

    case params['authResult']
    when 'AUTHORISED'
      @attributes = {
        psp_reference: params['pspReference'],
        merchant_reference: params['merchantReference'],
      }
      erb :authorized
    else
      status 400
      body params['authResult']
    end
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

    @attributes = {
      psp_reference: response['payment_result']['psp_reference']
    }

    if response['payment_result']['result_code'] == 'RedirectShopper'
      @term_url   = request.url.sub(%r{/pay\z}, '/pay/3dsecure')
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

  post '/pay/3dsecure' do
    response = Adyen::REST.client.api_request('Payment.authorise3d',
      payment_request_3d: {
        merchant_account: 'VanBergenORG',
        browser_info: {
          acceptHeader: request['Accept'] || "text/html;q=0.9,*/*",
          userAgent: request.user_agent
        },
        shopperIP: request.ip,
        pa_response: params['PaRes'],
        md: params['MD'],
      }
    )

    @attributes = {
      psp_reference: response['payment_result']['psp_reference'],
      auth_code: response['payment_result']['auth_code'],
    }

    erb :authorized
  end
end

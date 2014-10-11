require 'sinatra'

class Adyen::TestServer < Sinatra::Base
  set :views, File.join(File.dirname(__FILE__), 'views')
end

# encoding: UTF-8

require File.expand_path('../../lib/adyen', __FILE__)
require File.expand_path('../../lib/spec/matchers', __FILE__)

RSpec.configure do |config|
  config.include Adyen::Matchers
  config.include FactoryGirl::Syntax::Methods
end

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# RSpec and Factory Girl aren't loading the default path as they should
FactoryGirl.definition_file_paths = [File.expand_path('../factories', __FILE__)]
FactoryGirl.find_definitions

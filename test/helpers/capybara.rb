require 'helpers/example_server'
require 'capybara/dsl'
require 'capybara/poltergeist'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, phantomjs_options: ['--ssl-protocol=any'])
end

Capybara.default_driver = :poltergeist
Capybara.javascript_driver = :poltergeist
Capybara.app = Adyen::ExampleServer


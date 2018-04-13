require 'helpers/example_server'
require 'capybara/dsl'
require 'capybara/webkit'

Capybara.default_driver = :webkit
Capybara.javascript_driver = :webkit
Capybara.app = Adyen::ExampleServer

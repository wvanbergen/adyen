# encoding: UTF-8
require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/setup'
require 'capybara/poltergeist'
require 'capybara-screenshot'

require 'adyen'
require 'adyen/matchers'

require 'helpers/configure_adyen'
require 'helpers/example_server'
require 'helpers/test_cards'

require 'pp'

module Adyen::Test
  module Flaky
    def flaky_test(name, &block)
      define_method("test_#{name}") do
        attempt = 0
        test_instance = self
        begin
          attempt += 1
          test_instance.instance_eval(&block)
        rescue Minitest::Assertion
          attempt < 3 ? retry : raise
        end
      end
    end
  end

  module EachXMLBackend
    XML_BACKENDS = [Adyen::API::XMLQuerier::NokogiriBackend, Adyen::API::XMLQuerier::REXMLBackend]

    def for_each_xml_backend(&block)
      XML_BACKENDS.each do |xml_backend|
        begin
          Adyen::API::XMLQuerier.stubs(:default_backend).returns(xml_backend.new)
          block.call(xml_backend)
        ensure
          Adyen::API::XMLQuerier.unstub(:default_backend)
        end
      end
    end
  end
end


Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, phantomjs_options: ['--ssl-protocol=any'])
end

Capybara.default_driver = :poltergeist
Capybara.javascript_driver = :poltergeist
Capybara.app = Adyen::ExampleServer
Capybara.save_and_open_page_path = 'screenshots'

module Minitest::CapybaraScreenshot
  def before_setup
    super
    Capybara::Screenshot.final_session_name = nil
  end

  def after_teardown
    super
    if self.class.ancestors.include?(Capybara::DSL)
      if Capybara::Screenshot.autosave_on_failure && !passed?
        Capybara.using_session(Capybara::Screenshot.final_session_name) do
          filename_prefix = self.location

          saver = Capybara::Screenshot::Saver.new(Capybara, Capybara.page, true, filename_prefix)
          saver.save
        end
      end
    end
  end
end

class Minitest::Test
  include Minitest::CapybaraScreenshot
end

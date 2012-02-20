Gem::Specification.new do |s|
  s.name    = 'adyen'
  s.version = "1.3.1"
  s.date    = "2012-02-20"

  s.summary = "Integrate Adyen payment services in your Ruby on Rails application."
  s.description = <<-EOS
    Package to simplify including the Adyen payments services into a Ruby on Rails application.
    The package provides functionality to create payment forms, handling and storing notifications 
    sent by Adyen and consuming the SOAP services provided by Adyen. Moreover, it contains helper
    methods, mocks and matchers to simpify writing tests/specsfor your code.
  EOS

  s.authors  = ['Willem van Bergen', 'Michel Barbosa', 'Stefan Borsje', 'Eloy Duran']
  s.email    = ['willem@vanbergen.org', 'cicaboo@gmail.com', 'mail@sborsje.nl', 'eloy.de.enige@gmail.com']
  s.homepage = 'http://github.com/wvanbergen/adyen/wiki'

  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', '~> 2')
  s.add_development_dependency('rails', '>= 2.3')
  
  if RUBY_PLATFORM == 'java'
    s.add_development_dependency('nokogiri', '~> 1.4.6')
  else
    s.add_development_dependency('nokogiri')
  end
  
  s.add_runtime_dependency('jruby-openssl') if RUBY_PLATFORM == 'java'
  
  s.requirements << 'Having Nokogiri installed will speed up XML handling when using the SOAP API.'

  s.rdoc_options << '--title' << s.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  s.extra_rdoc_files = ['README.rdoc']

  s.files = %w(.gitignore .kick .travis.yml Gemfile LICENSE README.rdoc Rakefile TODO adyen.gemspec lib/adyen.rb lib/adyen/api.rb lib/adyen/api/cacert.pem lib/adyen/api/payment_service.rb lib/adyen/api/recurring_service.rb lib/adyen/api/response.rb lib/adyen/api/simple_soap_client.rb lib/adyen/api/templates/payment_service.rb lib/adyen/api/templates/recurring_service.rb lib/adyen/api/test_helpers.rb lib/adyen/api/xml_querier.rb lib/adyen/configuration.rb lib/adyen/encoding.rb lib/adyen/form.rb lib/adyen/formatter.rb lib/adyen/matchers.rb lib/adyen/notification_generator.rb lib/adyen/railtie.rb lib/adyen/templates/notification_migration.rb lib/adyen/templates/notification_model.rb spec/adyen_spec.rb spec/api/api_spec.rb spec/api/payment_service_spec.rb spec/api/recurring_service_spec.rb spec/api/response_spec.rb spec/api/simple_soap_client_spec.rb spec/api/spec_helper.rb spec/api/test_helpers_spec.rb spec/form_spec.rb spec/functional/api_spec.rb spec/functional/initializer.rb.sample spec/spec_helper.rb tasks/github-gem.rake yard_extensions.rb)
  s.test_files = %w(spec/adyen_spec.rb spec/api/api_spec.rb spec/api/payment_service_spec.rb spec/api/recurring_service_spec.rb spec/api/response_spec.rb spec/api/simple_soap_client_spec.rb spec/api/test_helpers_spec.rb spec/form_spec.rb spec/functional/api_spec.rb)
end

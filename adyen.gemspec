Gem::Specification.new do |s|
  s.name    = 'adyen'
  s.version = "0.1.4"
  s.date    = "2009-09-29"

  s.summary = "Integrate Adyen payment services in you Ruby on Rails application."
  s.description = <<-EOS
    Package to simplify including the Adyen payments services into a Ruby on Rails application.
    The package provides functionality to create payment forms, handling and storing notifications 
    sent by Adyen and consuming the SOAP services provided by Adyen. Moreover, it contains helper
    methods, mocks and matchers to simpify writing tests/specsfor your code.
  EOS

  s.authors  = ['Willem van Bergen', 'Michel Barbosa']
  s.email    = ['willem@vanbergen.org', 'cicaboo@gmail.com']
  s.homepage = 'http://wiki.github.com/wvanbergen/adyen'

  s.add_development_dependency('rspec', '>= 1.1.4')
  s.add_development_dependency('git', '>= 1.1.0')

  s.requirements << 'Handsoap is required for accessing the SOAP services. See http://github.com/troelskn/handsoap.'
  s.requirements << 'LibXML is required for using the RSpec matchers.'
  s.requirements << 'ActiveRecord is required for storing the notifications in your database.'

  s.rdoc_options << '--title' << s.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  s.extra_rdoc_files = ['README.rdoc']

  s.files = %w(spec/spec_helper.rb lib/adyen/form.rb .gitignore LICENSE spec/soap_spec.rb spec/notification_spec.rb lib/adyen/soap.rb init.rb spec/adyen_spec.rb adyen.gemspec Rakefile tasks/github-gem.rake spec/form_spec.rb README.rdoc lib/adyen/notification.rb lib/adyen/matchers.rb lib/adyen/formatter.rb lib/adyen.rb lib/adyen/encoding.rb)
  s.test_files = %w(spec/soap_spec.rb spec/notification_spec.rb spec/adyen_spec.rb spec/form_spec.rb)
end

Gem::Specification.new do |s|
  s.name    = 'adyen'
  s.version = '0.1.0'
  s.date    = '2009-08-20'
  
  s.summary = "Integrate Adyen payment services in you Ruby on Rails application"
  s.description = "Package to simplify including the Adyen payments services into a Ruby on Rails application."
  
  s.authors  = ['Willem van Bergen', 'Michel Barbosa']
  s.email    = ['willem@vanbergen.org', 'cicaboo@gmail.com']
  s.homepage = 'http://www.adyen.com'
  
  s.add_development_dependency('rspec')
  
  s.rdoc_options << '--title' << s.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  s.extra_rdoc_files = ['README.rdoc']
  
  s.files = %w(LICENSE README.rdoc Rakefile init.rb lib lib/adyen lib/adyen.rb lib/adyen/encoding.rb lib/adyen/form.rb lib/adyen/formatter.rb lib/adyen/matchers.rb lib/adyen/notification.rb lib/adyen/soap.rb spec spec/adyen_spec.rb spec/form_spec.rb spec/notification_spec.rb spec/soap_spec.rb spec/spec_helper.rb tasks tasks/github-gem.rake)
  s.test_files = %w(spec/adyen_spec.rb spec/form_spec.rb spec/notification_spec.rb spec/soap_spec.rb)
end
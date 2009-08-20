Gem::Specification.new do |s|
  s.name    = 'adyen'
  s.version = '0.0.2'
  s.date    = '2009-08-20'
  
  s.summary = "Integrate Adyen payment services in you Ruby on Rails application"
  s.description = "Package to simplify including the Adyen payments services into a Ruby on Rails application."
  
  s.authors  = ['Willem van Bergen', 'Michel Barbosa']
  s.email    = ['willem@vanbergen.org', 'cicaboo@gmail.com']
  s.homepage = 'http://www.adyen.com'
  
  s.add_development_dependency('rspec')
  
  s.rdoc_options << '--title' << s.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  s.extra_rdoc_files = ['README.rdoc']
  
  s.files = %w(LICENSE README.rdoc Rakefile doc doc/classes doc/classes/Adyen doc/classes/Adyen.html doc/classes/Adyen/Encoding.html doc/classes/Adyen/Form.html doc/classes/Adyen/Formatter doc/classes/Adyen/Formatter.html doc/classes/Adyen/Formatter/DateTime.html doc/classes/Adyen/Formatter/Price.html doc/classes/Adyen/Matchers doc/classes/Adyen/Matchers.html doc/classes/Adyen/Matchers/HaveAdyenPaymentForm.html doc/classes/Adyen/Matchers/XPathPaymentFormCheck.html doc/classes/Adyen/Notification doc/classes/Adyen/Notification.html doc/classes/Adyen/Notification/HttpPost.html doc/classes/Adyen/Notification/Migration.html doc/classes/Adyen/SOAP doc/classes/Adyen/SOAP.html doc/classes/Adyen/SOAP/Base.html doc/classes/Adyen/SOAP/PaymentService.html doc/classes/Adyen/SOAP/RecurringService.html doc/created.rid doc/files doc/files/README_rdoc.html doc/files/lib doc/files/lib/adyen doc/files/lib/adyen/encoding_rb.html doc/files/lib/adyen/form_rb.html doc/files/lib/adyen/formatter_rb.html doc/files/lib/adyen/matchers_rb.html doc/files/lib/adyen/notification_rb.html doc/files/lib/adyen/soap_rb.html doc/files/lib/adyen_rb.html doc/fr_class_index.html doc/fr_file_index.html doc/fr_method_index.html doc/index.html doc/rdoc-style.css init.rb lib lib/adyen lib/adyen.rb lib/adyen/encoding.rb lib/adyen/form.rb lib/adyen/formatter.rb lib/adyen/matchers.rb lib/adyen/notification.rb lib/adyen/soap.rb pkg pkg/adyen-0.0.1.gem spec spec/adyen_spec.rb spec/form_spec.rb spec/notification_spec.rb spec/soap_spec.rb spec/spec_helper.rb tasks tasks/github-gem.rake)
  s.test_files = %w(spec/adyen_spec.rb spec/form_spec.rb spec/notification_spec.rb spec/soap_spec.rb)
end
Gem::Specification.new do |s|
  s.name    = 'adyen'
  s.version = '0.0.1'
  s.date    = '2009-08-06'
  
  s.summary = "Integrate Adyen payment services in you Ruby on Rails application"
  s.description = "Package to simplify including the Adyen payments services into a Ruby on Rails application."
  
  s.authors  = ['Willem van Bergen', 'Michel Borbosa']
  s.email    = ['willem@vanbergen.org', 'cicaboo@gmail.com']
  s.homepage = 'http://www.adyen.com'
  
#  s.has_rdoc = true
#  s.rdoc_options << '--title' << s.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
#  s.extra_rdoc_files = ['README.rdoc']
  
  s.files = %w(LICENSE README.rdoc Rakefile init.rb lib lib/adyen lib/adyen.rb lib/adyen/form.rb lib/adyen/matchers.rb spec spec/form_spec.rb spec/spec_helper.rb tasks tasks/github-gem.rake)
  s.test_files = %w(spec/form_spec.rb)
end
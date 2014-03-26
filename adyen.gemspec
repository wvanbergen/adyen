# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'adyen/version'

Gem::Specification.new do |s|
  s.name    = "adyen"
  s.version = Adyen::VERSION

  s.required_ruby_version = '>= 1.9.3'

  s.summary = "Integrate Adyen payment services in your Ruby on Rails application."
  s.description = <<-EOS
    Package to simplify including the Adyen payments services into a Ruby on Rails application.
    The package provides functionality to create payment forms, handling and storing notifications 
    sent by Adyen and consuming the SOAP services provided by Adyen. Moreover, it contains helper
    methods, mocks and matchers to simpify writing tests/specs for your code.
  EOS

  s.authors  = ['Willem van Bergen', 'Michel Barbosa', 'Stefan Borsje', 'Eloy Durán']
  s.email    = ['willem@vanbergen.org', 'cicaboo@gmail.com', 'mail@sborsje.nl', 'eloy.de.enige@gmail.com']
  s.homepage = 'http://github.com/wvanbergen/adyen/wiki'
  s.license  = 'MIT'

  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', '~> 2.14')
  
  s.add_development_dependency('rails', '>= 3.2')
  s.add_development_dependency('nokogiri', '>= 1.6.1')
  
  s.requirements << 'Having Nokogiri installed will speed up XML handling when using the SOAP API.'

  s.rdoc_options << '--title' << s.name << '--main' << 'README.rdoc' << '--line-numbers' << '--inline-source'
  s.extra_rdoc_files = ['README.rdoc']

  s.files = `git ls-files`.split($/)
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
end

source 'https://rubygems.org'
gemspec

platform :rbx do
  gem 'rubysl'
  gem 'racc'
end

if RUBY_VERSION =~ /^1\./
  gem 'mime-types', '< 3.0'
end

platform :jruby do
  gem 'jruby-openssl'
end

require "bundler/gem_tasks"
require "rspec/core/rake_task"

Dir['tasks/*.rake'].each { |file| load(file) }



RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = "./spec/**/*_spec.rb"
  task.rspec_opts = ['--color']
end

CACERT_PATH = 'lib/adyen/api/cacert.pem'

desc 'Update CA root certificates for the simple SOAP client'
task :update_cacert do
  tmp = '/tmp/cacert.pem.new'
  sh "curl -o #{tmp} http://curl.haxx.se/ca/cacert.pem"
  mv CACERT_PATH, '/tmp/cacert.pem.old'
  cp tmp, CACERT_PATH
end

# Update the cacert.pem file before each release.
task :build => :update_cacert do
  sh "git commit #{CACERT_PATH} -m '[API] Update CA root certificates file.'"
end

begin
  require 'rubygems'
  require 'yard'
  require File.expand_path('../yard_extensions', __FILE__)
  YARD::Rake::YardocTask.new do |y|
    y.options << '--no-private' << '--title' << "The 'Adyen payment service' library for Ruby"
  end
rescue LoadError
end

task :default => [:spec]

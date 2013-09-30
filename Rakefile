begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end
require "rspec/core/rake_task"

begin
  require 'rdoc/task'
rescue LoadError
  require 'rdoc/rdoc'
  require 'rake/rdoctask'
  RDoc::Task = Rake::RDocTask
end

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

RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Adyen'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load 'rails/tasks/engine.rake'


Bundler::GemHelper.install_tasks

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

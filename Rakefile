require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/testtask"

namespace(:test) do
  Rake::TestTask.new(:all) do |t|
    t.description = "Run all tests"
    t.libs << "test"
    t.test_files = FileList['test/**/*_test.rb']
  end

  Rake::TestTask.new(:unit) do |t|
    t.description = "Run unit tests"
    t.libs << "test"
    t.test_files = FileList['test/*_test.rb']
  end

  Rake::TestTask.new(:functional) do |t|
    t.description = "Run functional tests"
    t.libs << "test"
    t.test_files = FileList['test/functional/**/*_test.rb']
  end

  Rake::TestTask.new(:integration) do |t|
    t.description = "Run integration tests"
    t.libs << "test"
    t.test_files = FileList['test/integration/**/*_test.rb']
  end
end

desc "Run unit and functional tests"
task :test => %w{test:unit test:functional}

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

# # Update the cacert.pem file before each release.
# task :build => :update_cacert do
#   sh "git diff-index --quiet HEAD #{CACERT_PATH} || (git add #{CACERT_PATH} && git commit -m '[API] Update CA root certificates file.')"
# end

task :default => %w{test spec}

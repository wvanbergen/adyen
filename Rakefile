Dir[File.dirname(__FILE__) + "/tasks/*.rake"].each { |file| load(file) }

GithubGem::RakeTasks.new(:gem)

begin
  require 'rubygems'
  require 'yard'
  require File.expand_path('../yard_extensions', __FILE__)
  YARD::Rake::YardocTask.new
rescue LoadError
end

task :default => "spec:specdoc"

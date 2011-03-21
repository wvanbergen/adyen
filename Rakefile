Dir[File.dirname(__FILE__) + "/tasks/*.rake"].each { |file| load(file) }

GithubGem::RakeTasks.new(:gem)

begin
  require 'rubygems'
  require 'yard'
  require File.expand_path('../yard_extensions', __FILE__)
  YARD::Rake::YardocTask.new do |y|
    y.options << '--no-private' << '--title' << "The 'Adyen payment service' library for Ruby"
  end
rescue LoadError
end

task :default => "spec:specdoc"

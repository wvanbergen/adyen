$LOAD_PATH.unshift(File.expand_path('../lib', __FILE__))
$LOAD_PATH.unshift(File.expand_path('../test', __FILE__))

require 'helpers/example_server'
run Adyen::ExampleServer.new

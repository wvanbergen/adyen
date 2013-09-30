Adyen::Engine.routes.draw do
  post 'notify' => 'notifications#notify'
end

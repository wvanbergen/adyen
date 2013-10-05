Adyen::Engine.routes.draw do
  post 'notify' => 'notifications#notify'
  get 'payments/result' => 'payments#result'
  get 'payments/complete' => 'payments#complete'
end

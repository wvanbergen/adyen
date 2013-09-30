Rails.application.routes.draw do

  mount Adyen::Engine => "/adyen"
end

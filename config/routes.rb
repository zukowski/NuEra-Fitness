NuEraFitness::Application.routes.draw do
  root :to => "content#home"

  match '/cart/quote', :to => 'orders#quote', :via => :post, :as => :quote_cart

  namespace :admin do
    resources :suppliers
    resources :packages
  end
end

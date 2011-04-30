NuEraFitness::Application.routes.draw do
  root :to => "content#home"

  namespace :admin do
    resources :suppliers
    resources :packages
  end
end

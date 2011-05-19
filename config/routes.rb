NuEraFitness::Application.routes.draw do
  root :to => "content#home"

  match '/cart/quote', :to => 'orders#quote', :via => :post, :as => :quote_cart

  namespace :admin do
    resources :suppliers
    resources :videos
    resources :products do
      resource :package, :only => [:edit, :update] do
        delete :remove_variant, :on => :member
      end
    end
  end
end

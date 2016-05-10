def disable_route(prefix, redirect="homepage#index")
  get "#{prefix}/*rest", to: redirect
  post "#{prefix}/*rest", to: redirect
  delete "#{prefix}/*rest", to: redirect
  put "#{prefix}/*rest", to: redirect
  patch "#{prefix}/*rest", to: redirect
  get "#{prefix}", to: redirect
  post "#{prefix}", to: redirect
  delete "#{prefix}", to: redirect
  put "#{prefix}", to: redirect
  patch "#{prefix}", to: redirect
end

Rails.application.routes.draw do
#  mount Qa::Engine => '/qa'

  resources :people
  blacklight_for :catalog

  # this enables users/sign_in and users/sign_out
  devise_for :users

  # enable users index only, needed by user auto complete
  get "users" => "users#index"
  # enable user proxy management
  post 'users/:user_id/depositors' => 'depositors#create'
  delete 'users/:user_id/depositors/:id' => 'depositors#destroy'

  # These have to be defined before what they are disabling.
  disable_route 'users'
  disable_route 'bookmarks'

  mount Hydra::RoleManagement::Engine => '/'

  Hydra::BatchEdit.add_routes(self)

  resources :doi, only: [:show, :update]

  # The id regex needs to allow doi identifiers doi:10.1234/abcdefgh, but not capture
  # format .json at the end
  get 'id/:id', to: 'identifiers#show', constraints: { id: /[a-z]+:[0-9\.]*\/[^\.]+?/ }  

  # This must be the very last route in the file because it has a catch-all route for 404 errors.
    # This behavior seems to show up only in production mode.
    mount Sufia::Engine => '/'
  root to: 'homepage#index'
  
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  resources :files, as: 'generic_file', except: [ :index ]
  resources :collections

end

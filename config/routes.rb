Rails.application.routes.draw do
  resources :articles
  devise_for :users, controllers: {
    registrations: 'user/registrations'
  }
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

  root to: 'home#index'

  get 'devices' => 'devices#index'
  get 'devices/:id' => 'devices#show', as: :device
  post 'devices/:id/fetch_new_info' => 'devices#fetch_new_info', as: :device_fetch_new_info
  post 'devices/:id/configure_logger' => 'devices#configure_logger', as: :device_configure_logger
  post 'devices/:id/fetch_logs' => 'devices#fetch_logs', as: :device_fetch_logs
  get 'devices/:id/download/:file' => 'devices#download_log', as: :device_download_log
end

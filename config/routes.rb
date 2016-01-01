Rails.application.routes.draw do
  root 'tables#index'
  
  get 'tables/create' => 'tables#create'
  
  post 'tables/new' => 'tables#new'

  get 'tables/edit' => 'tables#edit'

  get 'tables/show' => 'tables#show'
  
  get 'tables/' => 'tables#index'
  
  get 'tables/analysis' => 'tables#analysis'
  
  get 'tables/seed' => 'tables#seed'
  
  delete 'tables/delete' => 'tables#delete'
  
  post 'tables/update' => 'tables#update'
  
  post 'tables/get_products' => 'tables#get_products'
  
  post 'tables/update_tables_item_type_index' => 'tables#update_tables_item_type_index'

  post 'tables/update_tables_brand_name_index' => 'tables#update_tables_brand_name_index'
  
  post 'tables/update_tables_validations' => 'tables#update_tables_validations'
  
  get 'tables/appraisal' => 'tables#appraisal_index'
  
  post 'tables/appraisal' => 'tables#appraisal_results'


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
end

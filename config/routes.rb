Rails.application.routes.draw do
  namespace :system do
  get 'configuration/index'
  end

  namespace :system do
  get 'configuration/update'
  end

  namespace :system do
  get 'configuration/edit'
  end

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
  captcha_route
  root to: 'sessions#new'
  resources :sessions, only: [:new, :create]
  get '/logout', to: 'sessions#destroy'
  namespace :merchant do
    resources :merchant_stores do
      patch 'submit_audit', to: 'merchant_stores#submit_audit'
      patch 'reject_audit', to: 'merchant_stores#reject_audit'
      patch 'approve_audit', to: 'merchant_stores#approve_audit'
      patch 'enable', to: 'merchant_stores#enable'
      patch 'disable', to: 'merchant_stores#disable'
      resources :payment_plans, only: [:index, :destroy] do
        patch 'disable', to: 'payment_plans#disable'
        patch 'enable', to: 'payment_plans#enable'
      end
      resources :members, only: [:index]
      resources :bank_discounts, only: [:new, :create, :edit, :update], as: :merchant_bank_discounts
      resources :none_payment_plans, only: [:edit, :update], as: :merchant_none_payment_plans
      resources :credit_backs, only: [:new, :create, :edit, :update], as: :merchant_credit_backs
    end
    resources :acquirer_orgs, except: [:show]
  end

  namespace :trade do
    resources :transaction_logs, only: [:index, :show]
    resources :transactions, only: [:index, :show]
    resources :transaction_archives, only: [:index, :show]
    resources :voucher_transaction_logs, only: [:index, :show]
  end

  namespace :member do
    resources :individual_credit_accounts, only: [:index, :show] do
      resources :bank_cards, only: [:index]
      resources :vouchers, only: [:index]
      resources :referees, only: [:index]
    end
  end

  namespace :system do
    resources :activity_logs, only: [:index]
    resources :configurations, only: [:index, :edit, :update]
    resources :platform_accounts, except: [:show]
  end

  namespace :users do
    resources :system_users, except: [:show]
  end
end

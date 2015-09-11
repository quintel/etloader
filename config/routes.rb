Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users" }

  resources :testing_grounds do
    collection do
      get  'import'
      post 'import', to: :perform_import
      post 'calculate_concurrency'
    end

    member do
      get  'export', 'technology_profile'
      post 'data'
      post 'export', to: :perform_export
      patch 'save_as'
    end

    resources :business_cases, only: [:create, :show, :update] do
      member do
        post 'compare_with'
        get 'data'
      end
    end
  end

  resources :price_curves, as: :price_curve
  resources :load_profiles do
    resources :load_profile_component, only: :show
  end
  resources :topologies do
    member do
      patch :clone
    end
  end
  resources :market_models do
    member do
      patch :clone
    end
  end

  root to: redirect('/welcome')

  get ':id', to: 'pages#show', as: :page
end

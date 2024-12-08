Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # Health check routes
  get 'up' => 'rails/health#show', as: :rails_health_check
  get 'health' => 'rails/health#show', as: :health_check
  # Defines the root path route ("/")
  root to: 'rails/health#show'
  # root "posts#index"
  resources :stored_files, only: %i[create index update], param: :name do
    collection do
      get 'word_count'
      get 'freq_words'
      post 'check_hash'
    end
  end
  delete '/stored_files/:name', to: 'stored_files#destroy', as: 'delete_stored_file', constraints: { name: /[a-zA-Z0-9\.]+/ }
end

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  # Defines the root path route ("/")
  # root "posts#index"
  resources :stored_files, only: [:create, :index] do
    collection do
      get 'word_count'
      get 'freq_words'
    end
  end

  put 'stored_file', to: 'stored_files#update', as: :update_storagefile
  put 'stored_file', to: 'stored_files#destroy', as: :destroy_storagefile
end

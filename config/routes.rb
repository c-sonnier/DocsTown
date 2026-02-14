Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Authentication
  get "/auth/github/callback", to: "sessions#create"
  get "/auth/failure", to: "sessions#failure"
  delete "/logout", to: "sessions#destroy"

  resources :tasks, only: [ :index, :show ] do
    resource :vote, only: [ :create, :destroy ]
  end

  namespace :admin do
    resources :tasks, only: [ :index, :show ] do
      member do
        post :approve
        post :reject
      end
    end
  end

  resource :profile, only: [ :show, :update ]
  get "/unsubscribe/:token", to: "unsubscribes#show", as: :unsubscribe
  post "/unsubscribe/:token", to: "unsubscribes#create"

  authenticated = ->(request) { request.session[:user_id].present? }
  constraints(authenticated) do
    root to: "dashboards#show", as: :authenticated_root
  end
  root to: "pages#landing"
end

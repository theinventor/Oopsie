Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :projects do
    member do
      get :settings
    end
    resources :error_groups, only: [ :show ] do
      member do
        patch :resolve
        patch :ignore
        patch :unresolve
      end
    end
    resources :notification_rules, only: [ :create, :edit, :update, :destroy ] do
      member do
        patch :toggle
      end
    end
  end

  namespace :api do
    namespace :v1 do
      resources :exceptions, only: [ :create ]
      resource :project, only: [ :show ]
      resources :error_groups, only: [ :index, :show ] do
        member do
          patch :resolve
          patch :ignore
          patch :unresolve
        end
      end
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "cli" => "cli#show", as: :cli

  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboard#index"
end

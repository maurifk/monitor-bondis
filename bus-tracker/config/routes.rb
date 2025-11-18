Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "buses#index"
  resources :buses, only: [ :index, :show ]
  resources :stops, only: [ :index, :show ]
  
  # Bus tracking routes
  get "tracking", to: "tracking#index", as: :tracking_index
  get "tracking/dashboard", to: "tracking#dashboard", as: :tracking_dashboard
  post "tracking/start", to: "tracking#start_tracking", as: :start_tracking
  post "tracking/stop", to: "tracking#stop_tracking", as: :stop_tracking
end

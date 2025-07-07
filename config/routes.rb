Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  root "static_pages#landing_page"
  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.slim)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  resources :exams do
    resources :user_exams, only: %i[new create]
  end
  resources :user_exams, only: %i[index show edit update]
  get 'analytics', to: 'analytics#index', as: :analytics
end

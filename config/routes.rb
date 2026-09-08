Rails.application.routes.draw do
  devise_for :users, path: "api/v1/auth", controllers: {
    sessions: "api/v1/users/sessions",
    registrations: "api/v1/users/registrations",
    confirmations: "api/v1/users/confirmations",
    passwords: "api/v1/users/passwords"
  }

  namespace :api do
    namespace :v1 do
      get "me", to: "users#me"

      resources :courses, only: %i[index show create update destroy]

      resources :enrollments, only: %i[index show create destroy] do
        member do
          post :renew
          post :attendance
        end
      end

      namespace :admin do
        resources :reports, only: :index
        resources :stats, only: :index
        resources :notifications, only: :create
        resources :students, only: [] do
          member do
            post :deactivate
          end
        end
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount ActionCable.server => "/cable"

  namespace :api do
    namespace :v1 do
      scope :auth do
        post   "register", to: "auth#register"
        post   "login",    to: "auth#login"
        post   "refresh",  to: "auth#refresh"
        delete "logout",   to: "auth#logout"
        get    "me",       to: "auth#me"
      end

      resources :permissions, only: [:index, :show, :create, :update, :destroy] do
        member do
          get    :users
          post   "users/:user_id", action: :grant_user
          delete "users/:user_id", action: :revoke_user
        end
      end

      resources :users, only: [:index, :show, :update, :destroy] do
        member do
          patch :update_role
        end
      end

      resources :todos do
        collection do
          get :deleted
        end
        member do
          patch :restore
        end
      end

      resources :notifications, only: [:index] do
        collection do
          post :read_all
          post :demo
        end
        member do
          patch :read
        end
      end
    end
  end
end

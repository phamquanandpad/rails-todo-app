Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      scope :auth do
        post "register", to: "auth#register"
        post "login",    to: "auth#login"
        post "refresh",  to: "auth#refresh"
        delete "logout", to: "auth#logout"
      end

      resources :users, only: [:show, :update, :destroy]

      resources :todos do
        collection do
          get :deleted
        end
        member do
          patch :restore
        end
      end
    end
  end
end

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  post "in/:token" => "ingest#create"

  namespace :api do
    resources :sources, only: %i[index show create] do
      resources :subscriptions, only: %i[index create], shallow: true
    end
    resources :subscriptions, only: :update
    resources :events, only: %i[index show]
    resources :deliveries, only: :index do
      post :replay, on: :member
    end
  end
end

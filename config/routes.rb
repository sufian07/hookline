Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root to: redirect("/dashboard/")
  post "in/:token" => "ingest#create"
  post "demo/receiver" => "demo#receive"

  namespace :api do
    resource :session, only: :show
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

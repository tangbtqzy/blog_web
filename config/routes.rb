Rails.application.routes.draw do
  resources :comment,only: [:index, :create,:new,:show]
  #resources :tangbt
  root 'comment#home'

  resources :home, only: [:index, :create] do

  end 
end

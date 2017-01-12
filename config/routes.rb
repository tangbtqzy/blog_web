Rails.application.routes.draw do
  resources :comment,only: [:index, :create,:new,:show]
  #resources :tangbt
  # root 'comment#home'
  root 'welcome#index'

  resources :home, only: [:index, :create] do
  	collection do
  		get 'upfiles'
  	end
  end

  resources :mark, :share, :knowledge, :book, :life, :about, :welcome do
    
  end

  # system background
  namespace :admin do
    root 'login#index'

    resources :login, only: [:index, :new] do

    end
  end
end

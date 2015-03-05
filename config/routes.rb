Rails.application.routes.draw do
  resources :comment,only: [:index, :create,:new,:show]
  get 'get_content' => 'comment#get_content'
  #resources :tangbt
  root 'comment#home'
end

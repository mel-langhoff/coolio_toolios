Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  get 'pimp_my_res', to: 'pimp_my_res#new', as: :pimp_my_res
  post 'pimp_my_res', to: 'pimp_my_res#create'
  get 'chatbot', to: 'xzibit#index', as: :xzibit
end

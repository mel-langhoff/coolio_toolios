Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  
  get '/pimp_my_res', to: 'pimp_my_res#new', as: :pimp_my_res
  post '/pimp_my_res', to: 'pimp_my_res#create', as: :pimp_my_res_create
  get 'pimp_my_res/:id', to: 'pimp_my_res#show', as: :pimp_my_res_show
  get '/chatbot', to: 'xzibit#index', as: :xzibit

  get 'hustles', to: 'hustles#index'
  get 'hustles/:id', to: 'hustles#show'
  get 'hustles/new', to: 'hustles#new'
  get 'hustles/create', to: 'hustles#create'
  get 'hustles/edit', to: 'hustles#edit'
  get 'hustles/update', to: 'hustles#update'
  get 'hustles/destroy', to: 'hustles#destroy'

  get 'peep_res/:id', to: 'pimp_my_res#show', as: :peep_res

  get 'resume_pdf/:id', to: 'resumes#show'
end

Rails.application.routes.draw do
  post 'service/execute', :defaults => { :format => 'text' }
  post 'service/command', :defaults => { :format => 'text' }
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end

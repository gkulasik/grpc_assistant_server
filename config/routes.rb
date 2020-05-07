Rails.application.routes.draw do
  post 'service/*service_name/execute/:method_name', to: 'service#execute', defaults: { format: 'text' }, as: :execute
  post 'service/*service_name/command/:method_name', to: 'service#command', defaults: { format: 'text' }, as: :command
end

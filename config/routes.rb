Rails.application.routes.draw do
  post '/webhooks/inbound', to: 'news#inbound'
  post '/webhooks/status', to: 'news#status'
end

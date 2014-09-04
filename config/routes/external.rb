Rails.application.routes.draw do
  mount External::API, at: '/external'
end
require 'sidekiq'
Sidekiq.configure_server do |config|
  config.redis = {size: 25, host: Settings.redis_host, port:  Settings.redis_port, namespace: 'core-system'}
end

Sidekiq.configure_client do |config|
  config.redis = {size: 100, host: Settings.redis_host, port: Settings.redis_port, namespace: 'core-system'}
end

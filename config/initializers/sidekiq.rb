require 'sidekiq'
redis_config = YAML.load(File.open("#{Rails.root}/config/redis.yml"))[Rails.env]
Sidekiq.configure_server do |config|
  config.redis = {size: 25, host: redis_config['redis_host'], port: redis_config['redis_port'], namespace: 'core-system'}
end

Sidekiq.configure_client do |config|
  config.redis = {size: 100, host: redis_config['redis_host'], port: redis_config['redis_port'], namespace: 'core-system'}
end

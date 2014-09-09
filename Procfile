core-system: bundle exec Puma -C config/puma.rb
worker: bundle exec sidekiq -r ./config/application.rb -C ./config/sidekiq.yml -g core-system-worker
scheduler: bundle exec clockwork ./config/clock.rb
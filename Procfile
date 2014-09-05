core-system: bundle exec thin -C config/core-system.yml -p $PORT --threaded start
worker: bundle exec sidekiq -r ./config/application.rb -C ./config/sidekiq.yml -g core-system-worker
scheduler: bundle exec clockwork ./config/clock.rb
require 'drones'
require 'connection_pool'
require 'naught'
Drone.logger = Rails.logger
module DronePool
  cattr_accessor :pool, :send_sms
  config = YAML.load(File.open("#{Rails.root}/config/drone.yml"))[Rails.env]
  self.pool = ConnectionPool.new(size: 20, timeout: 3) {
    if !config['rabbit_uri'].blank?
      Drone.new(config['rabbit_uri'])
    else
      Naught.build.new
    end
  }

  self.send_sms = config['send_sms']
end
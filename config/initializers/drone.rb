require 'drones'
require 'connection_pool'
require 'naught'
Drone.logger = Rails.logger
module DronePool
  cattr_accessor :pool
  self.pool = ConnectionPool.new(size: 20, timeout: 3) {
    if !Settings['rabbit_uri'].blank?
      Drone.new(config['rabbit_uri'])
    else
      Naught.build.new
    end
  }
end
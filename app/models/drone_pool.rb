require 'drones'
require 'connection_pool'
require 'naught'
class DronePool
  cattr_accessor :pool
  class << self
    def init_connection
      self.pool = ConnectionPool.new(size: 20, timeout: 3) {
        if !Settings['rabbit_uri'].blank?
          Drone.new(config['rabbit_uri'])
        else
          Naught.build.new
        end
      }
    end

    def re_init_connection
      unless self.pool.nil?
        self.pool.shutdown do |c|
          c.close
        end
        init_connection
      end
    end
  end
end
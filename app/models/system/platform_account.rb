require 'securerandom'
require 'digest'
module System
  class PlatformAccount < ActiveRecord::Base
    TARGETS = [CORE_ENGINE = 'core-engine', CORE_INTERFACE = 'core-interface']
    STATUSES = [ ACTIVE ='0', INACTIVE = '1']
    validates_uniqueness_of :account_name
    validates_inclusion_of :access_target, in: TARGETS
    validates_inclusion_of :status, in: STATUSES
    before_create :generate_access_key
    class << self
      def validate(access_token, access_target)
        self.where(access_key: access_token, access_target: access_target, status: ACTIVE).select('account_name').first
      end
    end

    private
    def generate_access_key
      self.access_key = Digest::MD5.hexdigest("#{Time.now.to_s}:#{SecureRandom.uuid}")
    end

  end
end
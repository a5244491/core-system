module System
  class Configuration < ActiveRecord::Base
    KEYS = [
        REFERER_RATE = 'referer_rate'
    ]

    class << self
      def get(key)
        item = self.where(key: key).first
        item.nil? ? nil : item.value
      end

      def set(key, value)
        item = self.where(key: key).first_or_create
        item.value = value.to_s
        item.save!
      end

      def remove(key)
        self.where(key: key).destroy_all
      end
    end
  end
end
class SmsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :sms
  cattr_accessor :send_sms

  def perform(mobile, content, priority = 100)
    logger.info "sending sms #{content} to mobile #{mobile}"
    if send_sms?
      DronePool.pool.with do |drone|
        begin
          drone.send_sms(mobile, content, priority)
        rescue StandardError => e
          logger.error("Can not send sms due to #{e.message}")
        end
      end
    end
  end

  private
  def send_sms?
    Settings.send_sms
  end
end
#encoding:utf-8
module CoreEngineHelper

  def finish_transaction(trans_id)
    logger.info("finishing transaction #{trans_id}")
    TransactionFinishWorker.perform_async(trans_id)
  end

  def send_sms(mobile, content, priority = 100)
    SmsWorker.perform_async(mobile, content, priority)
  end
end

class TransactionFinishWorker
  include Sidekiq::Worker
  sidekiq_options queue: :transactions, unqiue: true

  def perform(trans_id)
    begin
      transaction = _finish_transaction(trans_id)
      MarketingRuleWorker.perform_async(Merchant::MarketingRule::TRANSACTION, transaction.credit_account_id,
                                  transaction.merchant_store_id, transaction.ref_id
      )
    rescue Trade::TransactionNotFinishedError
      logger.error { "Transaction #{trans_id} not finished, do it later" }
      TransactionFinishWorker.perform_in(5.seconds, trans_id)
    rescue ActiveRecord::StaleObjectError => e
      logger.error { "Transaction #{trans_id} finish failed: #{e.message}, going to retry" }
      TransactionFinishWorker.perform_in(1.seconds, trans_id)
    rescue StandardError => e
      logger.error { "Transaction #{trans_id} finish failed: #{e.message}, transaction is discarded" }
      logger.error e.backtrace.join("\n")
    end
  end

  private
  def _finish_transaction(trans_id)
    #wrapped in transaction, ready for read/write separation
    transaction = Trade::Transaction.transaction do
      Trade::Transaction.where(ref_id: trans_id,).first
    end
    if transaction.nil?
      logger.info { "can not find transaction #{trans_id}, this request is discarded" }
    else
      if transaction.status == 1
        transaction.finish
        logger.info "#{transaction.transaction_type} transaction #{trans_id} finished successfully"
        if transaction.instance_of? Trade::RollBackTransaction
          logger.info { "transaction #{transaction.roll_back_ref} reverted with reason: #{transaction.reason}" }
        end
        sms = transaction.to_sms
        SmsWorker.perform_async(sms.mobile, sms.content) unless sms.nil?
      else
        logger.info { "transaction #{transaction.ref_id} cancelled with reason: #{transaction.reason}" }
        transaction.cancel
      end
    end
    transaction
  end
end
class Trade::TransactionKeeper
  cattr_accessor :logger
  self.logger = Logger.new(STDOUT)
  class << self
    include CoreEngineHelper
    def clean_up_transactions(ttl = 1.day)
      transactions = Trade::Transaction.where(confirmed: false).where('created_at < ?', ttl.ago)
      logger.info "about to cleanup #{transactions.size} transactions"
      transactions.each do |transaction|
        Trade::Transaction.transaction do
          attributes = transaction.attributes
          attributes.delete 'id'
          Trade::TransactionArchive.create!(attributes)
          transaction.destroy
          logger.info "#{transaction.transaction_type} transaction: #{transaction.ref_id} is moved to archive"
        end
      end
    end

    def reconfirm_transactions(ttl = 2.hours)
      transactions = Trade::Transaction.where(confirmed: true).where('created_at < ?', ttl.ago).to_a
      logger.info "about to reconfirm #{transactions.size} transactions"
      transactions.each do |transaction|
        finish_transaction(transaction.ref_id)
        logger.info "#{transaction.transaction_type} transaction: #{transaction.ref_id} is reconfirmed"
      end
    end
  end
end
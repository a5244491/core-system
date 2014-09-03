module Trade
  class RollBackTransaction < Transaction
    class << self
      def sti_name
        Transaction::ROLL_BACK
      end
    end

    def finish
      raise TransactionNotFinishedError unless Transaction.where(ref_id: self.roll_back_ref).first.nil?
      self.class.transaction do
        master_log = TransactionLog.where(ref_id: self.roll_back_ref, status: TransactionLog::NORMAL, log_type: TransactionLog::PRIMARY).recent.first
        raise StandardError, "can not find master log with ref_id = #{self.roll_back_ref}" if master_log.nil?
        reverted = !TransactionLog.where(ref_id: self.roll_back_ref, status: TransactionLog::REVERTED, log_type: TransactionLog::PRIMARY).recent.first.nil?
        unless reverted
          credit_account = Member::CreditAccount.where(id: master_log.credit_account_id).first
          vice_logs = TransactionLog.where(ref_id: self.roll_back_ref, status: TransactionLog::NORMAL, log_type: TransactionLog::VICE).recent
          unless credit_account.nil?
            if master_log.credit_delta.to_i != 0
              credit_account.apply_consumption_credit!(master_log.credit_delta * -1, master_log.media_num)
              credit_account.consumption_times -= 1
              credit_account.save!
            end
          end
          revert_log = prepare_revert_log(master_log)
          revert_log.save!

          vice_logs.each do |vice_log|
            if vice_log.transaction_type == 'referer_credit'
              unless credit_account.nil? && vice_log.credit_delta.to_i != 0
                credit_account.apply_referer_credit!(-1 * vice_log.credit_delta)
                reverted_log = prepare_revert_log(vice_log)
                reverted_log.save!
              end
            end
          end
        end
        revert_vouchers
        self.destroy
      end
    end

    private
    def prepare_revert_log(log)
      revert_log = log.dup
      revert_log.transaction_datetime = log.transaction_datetime
      revert_log.status = Trade::TransactionLog::REVERTED
      revert_log.actual_money_amount = -1 * log.actual_money_amount.to_i
      revert_log.money_amount = -1 * log.money_amount
      revert_log.merchant_amount = -1 * log.merchant_amount.to_i
      revert_log.credit_delta = -1 * log.credit_delta.to_i
      revert_log
    end

    def revert_vouchers
      voucher_logs = VoucherTransactionLog.where(primary_transaction_ref_id: self.roll_back_ref, transaction_type: VoucherTransactionLog::USE).recent
      Member::Voucher.where(unique_id: voucher_logs.map{|log|log.voucher_unique_id}).update_all(status: Member::Voucher::NOT_USED) unless voucher_logs.size == 0
      voucher_logs.destroy_all
      voucher_logs = VoucherTransactionLog.where(primary_transaction_ref_id: self.roll_back_ref, transaction_type: VoucherTransactionLog::ISSUE).recent
      Member::Voucher.where(unique_id: voucher_logs.map{|log|log.voucher_unique_id}).destroy_all unless voucher_logs.size == 0
    end
  end
end
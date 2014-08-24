module Member
  class CreditCashingApplication < ActiveRecord::Base
    STATUS = [PROCESSING=101, REJECTED=201, PROCESSED=301]
    CASHING_MIN_AMOUNT=5000
    CASHING_EVERY_MIN_AMOUNT=1000
    belongs_to :credit_account
    validates_inclusion_of :status, in: STATUS

    def money_amount
      [amount.to_i/100 - 2, 0].max
    end

    def money_amount_includes_fee
      amount.to_i / 100
    end

    def approve!(comment = nil)
      self.class.transaction do
        self.status =PROCESSED
        self.comment = comment
        self.credit_account.approve_credit_cashing!(self.amount)
        self.save!
        transaction_log = Trade::TransactionLog.new
        transaction_log.log_type = Trade::TransactionLog::VICE
        transaction_log.transaction_type = Trade::TransactionLog::CREDIT_CASHING
        transaction_log.transaction_datetime = Time.now
        transaction_log.credit_delta = -1 * self.amount
        transaction_log.credit_account_id = self.credit_account.id
        transaction_log.mobile = self.credit_account.mobile
        transaction_log.customer_name = self.credit_account.name
        transaction_log.media_num = self.bank_card
        transaction_log.matched_bank = self.bank_name
        transaction_log.media_type = PaymentMedia::BANK_CARD
        transaction_log.status = Trade::TransactionLog::NORMAL
        transaction_log.internal_seq_num = 0
        transaction_log.user_tag = self.credit_account.tag
        transaction_log.ref_id = Trade::Transaction.new.send(:generate_ref_id)
        transaction_log.save!
      end
    end

    def reject!(comment = nil)
      self.class.transaction do
        self.status =REJECTED
        self.comment = comment
        self.credit_account.reject_credit_cashing!(self.amount)
        self.save!
      end
    end

    class << self
      def validation_cashing_amount(amount)
        raise ArgumentError, 'wrong cashing amount' if amount < CASHING_MIN_AMOUNT || amount % CASHING_EVERY_MIN_AMOUNT != 0
      end

      def processing
        where(status: PROCESSING)
      end

      def processed
        where(status: PROCESSED)
      end

      def rejected
        where(status: REJECTED)
      end
    end

    class NameNotSetError < StandardError
    end

    class NotEnoughCreditError < StandardError
    end

    class NoCashingAccountError < StandardError
    end
  end
end


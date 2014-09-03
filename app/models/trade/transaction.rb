require 'securerandom'
require 'digest'
module Trade
  class Transaction < ActiveRecord::Base
    self.inheritance_column = 'transaction_type'
    TRANSACTION_TYPES = Pay::PaymentPlan::PLAN_TYPES.concat([ROLL_BACK = 'roll_back'])
    TRANSACTION_STATUSES = [SUCCESS = 1, CANCEL = 0]
    validates_inclusion_of :transaction_type, in: TRANSACTION_TYPES
    before_create :generate_ref_id
    serialize :voucher_info
    belongs_to :credit_account, foreign_key: 'credit_account_id', class_name: 'Member::CreditAccount'
    belongs_to :payment_media, foreign_key: 'media_num', primary_key: 'media_num'

    default_scope { includes(:credit_account) }
    attr_accessor :plan_name
    before_save :fill_transaction_datetime

    delegate :referer_account, to: :credit_account, allow_nil: true

    TYPE_MAP = {
        Pay::PaymentPlan::CREDIT_BACK => 'Trade::CreditBackTransaction',
        Pay::PaymentPlan::BANK_DISCOUNT => 'Trade::BankDiscountTransaction',
        Pay::PaymentPlan::NONE => 'Trade::NonePaymentPlanTransaction',
        ROLL_BACK => 'Trade::RollBackTransaction'
    }

    class << self
      def find_sti_class(type_name)
        super(TYPE_MAP[type_name.to_s])
      end

      def transaction_log_type
        raise NotImplementedError
      end
    end

    def done
      apply_consumer_credit
      master_transaction_log = prepare_transaction_log(self.credit_account, self.class.transaction_log_type, Trade::TransactionLog::PRIMARY, 0)
      master_transaction_log.credit_delta = self.consumer_credit
      master_transaction_log.voucher_used_count = voucher_used_amount
      master_transaction_log.voucher_deducted_amount = voucher_deducted_amount
      master_transaction_log.save!
      accumulate_credit_account_statistic
      apply_referer_credit
      settle_vouchers
    end

    def finish
      self.class.transaction do
        self.done
        self.destroy
      end
      self
    end

    def cancel
      self.destroy
      self
    end

    def to_sms
      nil
    end

    def voucher_deducted_amount
      voucher_deducted_amount = 0
      unless self.voucher_info.nil?
        self.voucher_info.each { |v| voucher_deducted_amount += v.deducted_amount.to_i }
      end
      voucher_deducted_amount
    end

    def voucher_used_amount
      self.voucher_info.nil? ? 0 : self.voucher_info.size
    end

    def add_used_vouchers(voucher, deducted_amount)
      self.voucher_info ||= []
      self.voucher_info << OpenStruct.new({voucher_id: voucher.id, deducted_amount: deducted_amount})
    end

    private
    def fill_transaction_datetime
      self.transaction_datetime ||= Time.now
    end

    def apply_consumer_credit
      if self.consumer_credit.to_i != 0
        unless self.credit_account.nil?
          self.credit_account.apply_consumption_credit!(self.consumer_credit, self.media_num)
        end
      end
    end

    def apply_referer_credit
      if self.referer_credit.to_i != 0
        unless self.referer_account.nil?
          self.credit_account.apply_referer_credit!(self.referer_credit)
          vice_transaction_log = prepare_transaction_log(self.referer_account, Trade::TransactionLog::REFERER_CREDIT, Trade::TransactionLog::VICE, 100)
          vice_transaction_log.credit_delta = self.referer_credit
          vice_transaction_log.money_amount = 0
          vice_transaction_log.actual_money_amount = 0
          vice_transaction_log.merchant_amount = 0
          vice_transaction_log.merchant_rate = nil
          vice_transaction_log.save!
        end
      end
    end

    def settle_vouchers
      unless self.voucher_info.nil? || self.voucher_info.size <= 0
        self.voucher_info.each do |vinfo|
          voucher_id = vinfo.voucher_id
          deducted_amount = vinfo.deducted_amount.to_i
          voucher = Member::Voucher.where(id: voucher_id).first
          voucher.use!(deducted_amount,
                       mobile: self.mobile,
                       transaction_datetime: self.transaction_datetime,
                       primary_transaction_ref_id: self.ref_id,
                       merchant_name: self.merchant_name,
                       merchant_num: self.merchant_num,
                       merchant_store_id: merchant_store_id
          )
        end
      end
    end

    def accumulate_credit_account_statistic
      unless self.credit_account.nil?
        self.credit_account.consumption_times +=1
        self.credit_account.save!
      end
    end

    protected
    def prepare_transaction_log(credit_account_to_log, transaction_type, log_type = Trade::TransactionLog::PRIMARY, internal_seq_num = 0)
      master_transaction_log = Trade::TransactionLog.new(log_type: log_type)
      master_transaction_log.transaction_datetime = self.transaction_datetime
      master_transaction_log.merchant_rate = self.merchant_rate
      master_transaction_log.transaction_type = transaction_type
      master_transaction_log.money_amount = self.money_amount
      master_transaction_log.actual_money_amount = self.actual_money_amount
      master_transaction_log.media_num = self.media_num
      master_transaction_log.media_type = self.media_type
      master_transaction_log.sequence_number = self.sequence_num
      master_transaction_log.payment_plan_id = self.payment_plan_id
      master_transaction_log.merchant_store_id = self.merchant_store_id
      master_transaction_log.terminal_num = self.terminal_num
      master_transaction_log.merchant_amount = self.merchant_amount
      master_transaction_log.merchant_name = self.merchant_name
      master_transaction_log.money_amount = self.money_amount
      master_transaction_log.merchant_num = self.merchant_num
      master_transaction_log.plan_type = self.plan_type
      if self.media_type == Member::PaymentMedia::BANK_CARD
        card_bin_matched = Bank::CardBin.card_bin_match(self.media_num)
        master_transaction_log.matched_bank = card_bin_matched.bank_name unless card_bin_matched.nil?
      end
      unless credit_account_to_log.nil?
        master_transaction_log.mobile = credit_account_to_log.mobile
        master_transaction_log.credit_account_id = credit_account_to_log.id
        master_transaction_log.customer_name = credit_account_to_log.name
        master_transaction_log.credit_account_external_id = credit_account_to_log.external_id
        _log_referer_info(master_transaction_log, credit_account_to_log.referer_account)
      end
      master_transaction_log.status = Trade::TransactionLog::NORMAL
      master_transaction_log.ref_id = self.ref_id
      master_transaction_log.internal_seq_num = internal_seq_num
      master_transaction_log.acquirer_code = self.acquirer_code
      master_transaction_log.merchant_tag = self.merchant_tag
      master_transaction_log.user_tag = self.user_tag
      master_transaction_log
    end

    private
    def _log_referer_info(log, referer = self.referer_account)
      unless referer.nil?
        log.referer_id = referer.id
        log.referer_external_id = referer.external_id
        log.referer_mobile = referer.mobile
      end
    end

    def generate_ref_id
      now = Time.now
      self.ref_id = Digest::MD5.hexdigest("#{now.to_i}:#{now.nsec}:#{SecureRandom.uuid}")
    end
  end
end
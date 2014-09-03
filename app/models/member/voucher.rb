require 'securerandom'
require 'digest'
module Member
  class Voucher < ActiveRecord::Base
    scope :not_used, -> { where(status: NOT_USED) }
    scope :used, -> { where(status: USED) }

    STATUS = [USED = 0, NOT_USED = 1]
    validates_inclusion_of :status, in: STATUS
    before_validation do
      self.status ||= NOT_USED
    end
    before_save do
      self.unique_id ||= Digest::MD5.hexdigest("#{Time.now.to_s}:#{SecureRandom.uuid}")
      generate_sequence_number
    end
    belongs_to :credit_account
    belongs_to :voucher_meta

    delegate :denomination, :global, :active?, :aliases, :applicable_type, :merchant_group_name, :merchant_store, :sequence, :money_condition, to: :voucher_meta, allow_nil: true

    def prepare_voucher_log(attributes)
      transaction_log = Trade::VoucherTransactionLog.new(attributes)
      transaction_log.issuer_identifier = voucher_meta.issuer_identifier
      transaction_log.issuer_name = voucher_meta.issuer_name
      transaction_log.issuer_type = voucher_meta.issuer_type
      transaction_log.settler_identifier = voucher_meta.settler_identifier
      transaction_log.settler_name = voucher_meta.settler_name
      transaction_log.settler_type = voucher_meta.settler_type
      transaction_log.denomination = voucher_meta.denomination
      transaction_log.voucher_meta_code = voucher_meta.code
      transaction_log.credit_account_id = self.credit_account_id
      transaction_log.mobile ||= self.credit_account.mobile
      transaction_log.voucher_unique_id = self.unique_id
      transaction_log.voucher_sequence_number = self.sequence_number
      transaction_log
    end

    def use!(deducted_amount, transaction_attrs = {})
      deducted_amount ||= self.denomination
      self.class.transaction do
        self.status = USED
        self.used_datetime = transaction_attrs[:transaction_datetime] || Time.now
        voucher_log = prepare_voucher_log(transaction_attrs.merge!(deducted_amount: deducted_amount, transaction_type: Member::VoucherTransactionLog::USE))
        voucher_log.save!
        save!
      end
    end

    private
    def generate_sequence_number
      unless sequence.nil? || !self.sequence_number.nil?
        sequence_number = sequence.allocate_sequence_number
        raise Member::VoucherMeta::VoucherAmountExceeded if sequence_number.nil?
        self.sequence_number = sequence_number
      end
    end
  end
end
require 'digest'
require 'composite_primary_keys'
module Trade
  class TransactionLog < ActiveRecord::Base
    include Checkable
    self.primary_keys = :id, :transaction_datetime
    LOG_TYPE = [PRIMARY = 1, VICE = 0]
    TRANSACTION_TYPE = [
        CREDIT_BACK = 'credit_back',
        COUPON = 'coupon',
        BANK_DISCOUNT ='bank_discount',
        NONE ='none',
        REFERER_CREDIT ='referer_credit',
        CREDIT_CASHING = 'credit_cashing'
    ]

    STATUSES = [
        NORMAL = 0,
        REVERTED = 1
    ]
    validates_inclusion_of :log_type, in: LOG_TYPE
    validates_inclusion_of :transaction_type, in: TRANSACTION_TYPE
    validates_inclusion_of :status, in: STATUSES

    scope :recent, ->(duration = 1.week) { where(transaction_datetime: duration.ago..duration.from_now) }
    scope :primary_log, -> { where(log_type: PRIMARY) }
    scope :vice_log, -> { where(log_type: VICE) }
  end
end
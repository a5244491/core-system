require 'securerandom'
require 'digest'
module Trade
  class Transaction < ActiveRecord::Base
    self.inheritance_column = 'transaction_type'
    TRANSACTION_TYPES =  Pay::PaymentPlan::PLAN_TYPES.concat([ROLL_BACK = 'roll_back'])
    TRANSACTION_STATUSES = [SUCCESS = 1, CANCEL = 0]
    validates_inclusion_of :transaction_type, in: TRANSACTION_TYPES
    before_create :generate_ref_id
    serialize :voucher_info
    belongs_to :credit_account, foreign_key: 'credit_account_id', class_name: 'Member::CreditAccount'
    belongs_to :payment_media, foreign_key: 'media_num', primary_key: 'media_num'

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
    end

    private
    def generate_ref_id
      now = Time.now
      self.ref_id = Digest::MD5.hexdigest("#{now.to_i}:#{now.nsec}:#{SecureRandom.uuid}")
    end
  end
end
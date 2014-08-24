module Pay
  class PaymentPlan < ActiveRecord::Base
    STATUSES = [VALID = 1, INVALID = 0]
    PLAN_TYPES = [CREDIT_BACK = 'credit_back', NONE = 'none', BANK_DISCOUNT = 'bank_discount']
    VOUCHER_STATUS = [ACCEPT_NONE = 0, ACCEPT_SELF = 1, ACCEPT_GLOBAL = 2, ACCEPT_ALL = 3]
    TYPE_MAP = {
        CREDIT_BACK => 'Pay::CreditBack',
        BANK_DISCOUNT => 'Pay::BankDiscount',
        NONE => 'Pay::NonePaymentPlan'
    }
    DISCOUNT_TYPES = [
        CASH = 'cash',
        RATE = 'rate'
    ]

    USER_TYPES = [ALL_USERS = 0, MEMBERS = 1, REFEREE = 2]

    self.inheritance_column = 'plan_type'
    belongs_to :merchant_store, class_name: Merchant::MerchantStore
    validates_inclusion_of :plan_type, in: PLAN_TYPES
    validates_inclusion_of :status, in: STATUSES
    validates_inclusion_of :voucher_status, in: VOUCHER_STATUS
    validates_inclusion_of :user_type, in: USER_TYPES
    has_and_belongs_to_many :marketing_rules,  ->{on_transaction}, class_name: 'Merchant::MarketingRule'

    before_validation do
      fill_up_date
      self.voucher_status ||= ACCEPT_NONE
      self.user_type ||= ALL_USERS
    end

    after_save do
      unless merchant_store.nil?
        merchant_store.accept_global_voucher = !merchant_store.payment_plans.where("voucher_status = #{ACCEPT_ALL} or  voucher_status = #{ACCEPT_GLOBAL}").first.nil?
        merchant_store.accept_own_voucher = !merchant_store.payment_plans.where("voucher_status = #{ACCEPT_ALL} or  voucher_status = #{ACCEPT_SELF}").first.nil?
        merchant_store.save!
      end
    end

    class << self
      def find_sti_class(type_name)
        super(TYPE_MAP[type_name.to_s])
      end

      def valid
        now = DateTime.now
        where(status: VALID).where('valid_from <= ?', now).where('valid_till >= ?', now)
      end

      def invalid
        now = DateTime.now
        where('status =? or valid_from > ? or valid_till < ?', INVALID, now, now)
      end
    end

    def is_valid?
      now = DateTime.now
      valid = (status == VALID)
      valid = valid && self.valid_from < now unless self.valid_from.nil?
      valid = valid && self.valid_till > now unless self.valid_till.nil?
      valid
    end

    def actual_referer_rate
      (self.referer_rate || System::Configuration.get(System::Configuration::REFERER_RATE)).to_f
    end

    def member_only?
      self.user_type != ALL_USERS
    end

    private
    def fill_up_date
      self.valid_from ||= DateTime.new(1976)
      self.valid_till ||= 10.years.from_now
    end
  end
end
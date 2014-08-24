require 'aasm'
module Merchant
  class MerchantStore < ActiveRecord::Base
    include AASM
    aasm column: :status, requires_new_transaction:false do
       state :editing, initial: true
       state :auditing
       state :audit_passed
       state :active
    end
    # STATUSES = [ENTERING = 0, AUDITING = 1, AUDITING_PASSED = 2, ACTIVE = 3, INACTIVE = 4]
    belongs_to :credit_account, class_name: 'Member::MerchantCreditAccount', :dependent => :destroy
    has_many :payment_plans, :dependent => :destroy, class_name: 'Pay::PaymentPlan'
    validates_presence_of :name, :merchant_number, :standard_rate
    validates_uniqueness_of :merchant_number
    belongs_to :acquire_org, class_name: 'Merchant::AcquirerOrg', foreign_key: :accquire_org_id
    has_many :merchant_group_ships, dependent: :destroy
    has_many :merchant_groups, through: :merchant_group_ships
    has_many :marketing_rules, ->{includes(:post_actions)}, dependent: :destroy
    has_many :member_ships, as: :member_group, class_name: Member::MemberShip
    has_many :member_accounts, through: :member_ships, source: :credit_account, class_name: Member::CreditAccount

    before_validation do
      self.accept_global_voucher ||= false
      self.accept_own_voucher ||= false
      true
    end
  end
end
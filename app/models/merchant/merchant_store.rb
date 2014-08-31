require 'aasm'
module Merchant
  class MerchantStore < ActiveRecord::Base
    include AASM
    # include Merchant::MerchantStoreEngineConcern
    aasm column: :status, requires_new_transaction:false do
       state :editing, initial: true
       state :auditing
       state :audit_passed
       state :active
       event :submit_audit do
         transitions from: :editing, to: :auditing
       end
       event :reject_audit do
         transitions from: [:audit_passed, :auditing], to: :editing
       end
       event :approve_audit do
         transitions from: :auditing, to: :audit_passed
       end
       event :enable do
         transitions from: :audit_passed, to: :active
       end
       event :disable do
         transitions from: :active, to: :audit_passed
       end
    end
    belongs_to :credit_account, class_name: 'Member::MerchantCreditAccount', :dependent => :destroy
    has_many :payment_plans, :dependent => :destroy, class_name: 'Pay::PaymentPlan'
    validates_presence_of :name, :merchant_number, :standard_rate
    validates_uniqueness_of :merchant_number, :merchant_name
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

    after_save :syn_credit_account_name

    after_create do
      self.create_credit_account
      self.payment_plans << Pay::NonePaymentPlan.create(status: Pay::NonePaymentPlan::VALID)
      self.save!
    end

    def may_destroy?
      editing?
    end

    def may_edit?
      editing?
    end

    def total_transaction_count_of_day(now)
      Trade::TransactionLog.where(merchant_store_id: id).where(transaction_datetime: now.beginning_of_day..now.end_of_day).count
    end

    def total_member_transaction_count_of_day(now)
      Trade::TransactionLog.where.not(transaction_type: Trade::TransactionLog::NONE).where(merchant_store_id: id).where(transaction_datetime: now.beginning_of_day..now.end_of_day).count
    end

    def new_registered_members_count_of_day(now)
      self.member_accounts.where(created_at: now.beginning_of_day..now.end_of_day).count
    end

    def total_transaction_amount_of_day(now)
      Trade::TransactionLog.where(merchant_store_id: id).where(transaction_datetime: now.beginning_of_day..now.end_of_day).sum(:actual_money_amount)
    end

    private
    def syn_credit_account_name
      unless self.credit_account.nil?
        self.credit_account.update(name: self.name)
      end
    end
  end
end
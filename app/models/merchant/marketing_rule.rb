module Merchant
  class MarketingRule < ActiveRecord::Base
    include Rule
    belongs_to :merchant_store
    self.inheritance_column = 'rule_type'
    EVENT_TYPES = [REGISTER = 'register', TRANSACTION = 'transaction', BIND_CARD = 'bind_card']
    TYPE_MAP = {
        REGISTER => 'Merchant::RegisterRule',
        TRANSACTION => 'Merchant::TransactionRule',
        BIND_CARD => 'Merchant::BindCardRule'
    }
    scope :on_transaction, -> { where(rule_type: TRANSACTION) }
    scope :on_register, -> { where(rule_type: REGISTER) }
    scope :on_bind_card, -> { where(rule_type: BIND_CARD) }

    has_many :post_actions, -> { includes(:voucher_meta) }
    has_and_belongs_to_many :payment_plans, class_name: 'Pay::PaymentPlan'
    class << self
      def find_sti_class(type_name)
        super(TYPE_MAP[type_name.to_s])
      end
    end

    def precondition_matches?(credit_account, current_transaction_log)
      true
    end

    def perform_post_actions(credit_account, current_transaction_log = nil)
      if precondition_matches?(credit_account, current_transaction_log)
        post_actions.each do |post_action|
          begin
            post_action.perform_action(credit_account: credit_account, merchant_store: self.merchant_store,
                                       trigger_event: self.rule_type, master_log: current_transaction_log)
          rescue StandardError => e
            logger.error("can not execute post action due to #{e.message}")
          end
        end
      end
    end
  end
end
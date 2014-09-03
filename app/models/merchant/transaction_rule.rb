module Merchant
  class TransactionRule < MarketingRule
    class << self
      def sti_name
        MarketingRule::TRANSACTION
      end
    end

    def precondition_matches?(credit_account, current_transaction_log)
      unless current_transaction_log.nil?
        current_transaction_log.actual_money_amount.to_i >= self.money_condition.to_i
      else
        false
      end
    end
  end
end
module Merchant
  class TransactionRule < MarketingRule
    class << self
      def sti_name
        MarketingRule::TRANSACTION
      end
    end
  end
end
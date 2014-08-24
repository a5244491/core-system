module Merchant
  class BindCardRule < MarketingRule
    class << self
      def sti_name
        MarketingRule::BIND_CARD
      end
    end
  end
end
module Merchant
  class RegisterRule < MarketingRule
    class << self
      def sti_name
        MarketingRule::REGISTER
      end
    end
  end
end
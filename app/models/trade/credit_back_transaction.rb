require_relative 'transaction'
module Trade
  class CreditBackTransaction < Transaction
    class << self
      def sti_name
        Pay::PaymentPlan::CREDIT_BACK
      end
    end
  end
end
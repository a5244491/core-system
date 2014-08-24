require_relative 'transaction'
module Trade
  class NonePaymentPlanTransaction < Transaction
    class << self
      def sti_name
        PaymentPlan::NONE
      end
    end
  end
end
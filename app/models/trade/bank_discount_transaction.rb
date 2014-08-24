require_relative 'transaction'
module Trade
  class BankDiscountTransaction < Transaction
    class << self
      def sti_name
        PaymentPlan::BANK_DISCOUNT
      end
    end
  end
end
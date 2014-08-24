module Pay
  class CreditBack < PaymentPlan
    validates_numericality_of :merchant_rate, less_than: 1
    validates_numericality_of :customer_rate, less_than: 1
    class << self
      def sti_name
        PaymentPlan::CREDIT_BACK
      end
    end
  end
end
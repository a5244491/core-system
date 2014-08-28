module Pay
  class CreditBack < PaymentPlan
    validates_numericality_of :merchant_rate, less_than: 1
    validates_numericality_of :customer_rate, less_than: 1
    before_validation do
      self.user_type = MEMBERS
    end
    class << self
      def sti_name
        PaymentPlan::CREDIT_BACK
      end
    end
  end
end
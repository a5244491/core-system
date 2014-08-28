module Pay
  class NonePaymentPlan < PaymentPlan
    after_validation :init_attr
    class << self
      def sti_name
        PaymentPlan::NONE
      end
    end

    def actual_referer_rate
      return 0
    end

    def init_attr
      self.merchant_rate = nil
      self.customer_rate = nil
      self.referer_rate = nil
    end

    def may_destroy?
      false
    end
  end
end
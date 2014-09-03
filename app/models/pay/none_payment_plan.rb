module Pay
  class NonePaymentPlan < PaymentPlan
    after_validation :init_attr
    class << self
      def sti_name
        PaymentPlan::NONE
      end
    end

    def plan_name
      '普通消费'
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

    protected
    def new_transaction(money_amount, credit_account = nil)
      transaction = Trade::NonePaymentPlanTransaction.new
      transaction.actual_money_amount = money_amount
      transaction
    end
  end
end
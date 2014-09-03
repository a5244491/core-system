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

    def plan_name
      '优惠返利'
    end

    protected
    def new_transaction(money_amount, credit_account = nil)
      transaction = Trade::CreditBackTransaction.new
      transaction.actual_money_amount = money_amount
      transaction
    end
  end
end
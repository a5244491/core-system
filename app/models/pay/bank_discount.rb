module Pay
  class BankDiscount < PaymentPlan
    validates_inclusion_of :discount_type, in: DISCOUNT_TYPES
    validates_with DiscountValidator
    before_validation :fill_minimal_money_amount

    class << self
      def sti_name
        PaymentPlan::BANK_DISCOUNT
      end
    end

    private
    def fill_minimal_money_amount
      self.minimal_money_amount ||= 0
    end
  end
end
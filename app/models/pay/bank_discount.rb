module Pay
  class BankDiscount < PaymentPlan
    before_validation :fill_default
    class DiscountValidator < ActiveModel::Validator
      def validate(record)
        if record.discount_amount < 0
          record.errors[:discount_amount] << 'discount_amount is invalid'
        end
        if record.discount_rate < 0 || record.discount_rate > 1
          record.errors[:discount_rate] << 'discount_rate is invalid'
        end
        if record.minimal_money_amount < 0
          record.errors[:minimal_money_amount] << 'minimal_money_amount is invalid'
        end
      end
    end
    validates_with DiscountValidator

    class << self
      def sti_name
        PaymentPlan::BANK_DISCOUNT
      end
    end



    def plan_name
      '刷卡打折'
    end

    protected
    def new_transaction(money_amount, credit_account = nil)
      transaction = Trade::BankDiscountTransaction.new
      transaction.merchant_rate = self.merchant_rate
      transaction.actual_money_amount = (money_amount * (1 - self.discount_rate) + 0.5).to_i
      transaction.actual_money_amount = [transaction.actual_money_amount - self.discount_amount, 0].max
      transaction.matched_bank = self.bank_name
      transaction
    end

    private
    def fill_default
      self.minimal_money_amount ||= 0
      self.discount_rate ||= 0
      self.discount_amount ||= 0
    end
  end
end
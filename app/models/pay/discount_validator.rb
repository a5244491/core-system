module Pay
  class DiscountValidator < ActiveModel::Validator
    def validate(record)
      if record.discount_type == Pay::PaymentPlan::CASH && (record.discount_amount.nil? || record.discount_amount < 0)
        record.errors[:discount_amount] << 'discount_amount is invalid'
      elsif record.discount_type == Pay::PaymentPlan::RATE && (record.discount_rate.nil? || record.discount_rate < 0 || record.discount_rate > 1)
        record.errors[:discount_rate] << 'discount_rate is invalid'
      end
      if !record.minimal_money_amount.nil? && record.minimal_money_amount < 0
        record.errors[:minimal_money_amount] << 'minimal_money_amount is invalid'
      end
    end
  end
end
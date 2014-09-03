require 'ostruct'
module Trade
  class BankDiscountTransaction < Transaction
    attr_accessor :discount_rate, :discount_amount
    class << self
      def sti_name
        Pay::PaymentPlan::BANK_DISCOUNT
      end

      def transaction_log_type
        Trade::TransactionLog::BANK_DISCOUNT
      end
    end

    def to_receipt
      pos_receipt = Receipt.new(self.plan_name)
      discount_amount = self.money_amount - self.actual_money_amount
      pos_receipt.extra_rows << "本次消费共获得优惠#{(discount_amount)/100.0}元" unless discount_amount == 0
      pos_receipt.extra_rows_m << "本次消费共获得优惠#{(discount_amount)/100.0}元" unless discount_amount == 0
      pos_receipt
    end

    def to_sms
      if voucher_used_amount != 0
        date_string = self.transaction_datetime.nil? ? nil : self.transaction_datetime.localtime.strftime('%Y年%-m月%d日%k时%M分')
        OpenStruct.new(mobile: self.mobile,
                       content: %Q{尊敬的爱刷会员，您于#{date_string}, 在#{self.merchant_name}消费#{self.actual_money_amount/100.0}元, 使用红包抵扣#{self.voucher_deducted_amount/100.0}元。详情请登录www.aishua.cn【爱刷】})
      else
        super
      end
    end
  end
end
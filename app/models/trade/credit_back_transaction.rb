require 'ostruct'
module Trade
  class CreditBackTransaction < Transaction
    class << self
      def sti_name
        Pay::PaymentPlan::CREDIT_BACK
      end

      def transaction_log_type
        Trade::TransactionLog::CREDIT_BACK
      end
    end

    def to_receipt
      pos_receipt = Receipt.new(self.plan_name)
      pos_receipt.extra_rows << "本次消费获得积分#{self.consumer_credit}"
      pos_receipt.extra_rows << '请登录爱刷平台管理及使用您的积分'
      pos_receipt.extra_rows_m << "本次消费获得积分#{self.consumer_credit}"
      pos_receipt.extra_rows_m << '请登录爱刷平台管理及使用您的积分'
      pos_receipt
    end

    def to_sms
      date_string = self.transaction_datetime.nil? ? nil : self.transaction_datetime.localtime.strftime('%m月%d日%k时%M分')
      voucher_text = %Q{使用红包抵扣#{self.voucher_deducted_amount}, } unless voucher_used_amount == 0
      OpenStruct.new(mobile: self.mobile,
                     content: %Q{尊敬的爱刷会员，您于#{date_string}, 在#{self.merchant_name}消费#{self.actual_money_amount/100.0}元, #{voucher_text}获得积分#{self.consumer_credit}。详情请登录www.aishua.cn【爱刷】})
    end
  end
end
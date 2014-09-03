require_relative 'transaction'
module Trade
  class NonePaymentPlanTransaction < Transaction
    class << self
      def sti_name
        Pay::PaymentPlan::NONE
      end

      def transaction_log_type
        Trade::TransactionLog::NONE
      end
    end

    def to_receipt
      pos_receipt = Receipt.new(self.plan_name)
      if self.credit_account_id.nil?
        pos_receipt.extra_rows << '注册成为爱刷会员可享受更多优惠'
        pos_receipt.extra_rows_m << '注册成为爱刷会员可享受更多优惠'
      else
        pos_receipt.extra_rows << '本次为普通刷卡,使用爱刷刷卡可享更多优惠'
        pos_receipt.extra_rows_m << '本次为普通刷卡,使用爱刷刷卡可享更多优惠'
      end
      pos_receipt
    end
  end
end
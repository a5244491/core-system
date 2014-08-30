module Trade::TransactionsHelper
  cattr_accessor :ongoing_transaction_type_hash
  self.ongoing_transaction_type_hash = {
      Pay::PaymentPlan::CREDIT_BACK => '积分返利',
      Pay::PaymentPlan::BANK_DISCOUNT => '刷卡打折',
      Pay::PaymentPlan::NONE => '普通刷卡',
      Trade::Transaction::ROLL_BACK => '交易回滚'
  }

  def ongoing_transaction_status_text(transaction)
    status = if transaction.status == 1
      '待完成'
    elsif transaction.status == 0
      '待取消'
    end
    confirmed = transaction.confirmed ? '已确认' : '未确认'
    "#{confirmed}, #{status}"
  end
end
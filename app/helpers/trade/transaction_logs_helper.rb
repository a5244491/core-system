module Trade::TransactionLogsHelper
  cattr_accessor :transaction_type_hash
  self.transaction_type_hash = {
      Trade::TransactionLog::CREDIT_BACK => '积分返利',
      Trade::TransactionLog::COUPON => '优惠券',
      Trade::TransactionLog::BANK_DISCOUNT => '刷卡打折',
      Trade::TransactionLog::NONE => '普通刷卡',
      Trade::TransactionLog::REFERER_CREDIT => '推荐人积分',
      Trade::TransactionLog::CREDIT_CASHING => '积分兑现'
  }

  def transaction_status_text(log)
    if log.status == Trade::TransactionLog::REVERTED
      '回滚'
    else
      '正常'
    end
  end

  def merchant_rate_text(log)
    log.merchant_rate.nil? ? '标准扣率' : log.merchant_rate.to_f * 100
  end

  def voucher_info_text(transaction_log)
    transaction_log.voucher_used_count.to_i == 0 ? '' : "使用红包#{transaction_log.voucher_used_count.to_i}个/抵扣#{money_in_yuan(transaction_log.voucher_deducted_amount)}元"
  end
end

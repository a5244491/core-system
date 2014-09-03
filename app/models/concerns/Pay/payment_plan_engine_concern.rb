module Pay::PaymentPlanEngineConcern
  extend ActiveSupport::Concern
  def plan_name
    '未知类型'
  end

  def create_transaction(money_amount, credit_account = nil)
    transaction = new_transaction(money_amount, credit_account)
    raise Pay::PaymentPlanError('支付计划异常') if transaction.actual_money_amount > money_amount
    #计算红包
    apply_vouchers(transaction, credit_account)
    transaction
  end

  def accept_global_voucher?
    self.voucher_status == Pay::PaymentPlan::ACCEPT_GLOBAL || self.voucher_status ==  Pay::PaymentPlan::ACCEPT_ALL
  end

  def accept_vouchers?
    !self.voucher_status.nil? && self.voucher_status !=  Pay::PaymentPlan::ACCEPT_NONE
  end

  protected
  def new_transaction(money_amount, credit_account)
    raise Pay::NotImplementedError
  end

  private
  def apply_vouchers(transaction, credit_account)
    unless credit_account.nil? || !accept_vouchers?
      _apply_vouchers(transaction, _usable_vouchers(credit_account, transaction.actual_money_amount))
    end
  end

  def _usable_vouchers(credit_account, money_amount)
    groups = nil
    credit_account.vouchers.not_used.includes(voucher_meta: [:merchant_store, :merchant_group]).select do |voucher|
      if voucher.active? && money_amount >= voucher.money_condition
        case voucher.applicable_type
          when Member::VoucherMeta::ALL_STORE
            true
          when Member::VoucherMeta::SINGLE_STORE
            self.merchant_store.id == voucher.merchant_store.id
          when Member::VoucherMeta::STORE_GROUP
            groups ||= self.merchant_store.merchant_groups.map { |group| group.name }
            groups.include?(voucher.merchant_group_name)
        end
      else
        false
      end
    end
  end

  def _apply_vouchers(transaction, usable_vouchers)
    amount = transaction.actual_money_amount
    amount_after_deduction = amount
    if amount > 1 and usable_vouchers.size > 0
      #找到比交易金额大的最小面额红包
      bigger_voucher = usable_vouchers.select { |voucher| voucher.denomination >= amount }.min_by { |voucher| voucher.denomination }
      unless bigger_voucher.nil?
        deducted_amount = amount - 1 #交易至少需要一分钱, 在这种情况下实际抵扣额度要比交易额少一分
        transaction.add_used_vouchers(bigger_voucher, deducted_amount)
        amount_after_deduction = 1
      else
        #找比交易金额小的红包, 从大到小开始使用
        smaller_voucher = usable_vouchers.select { |voucher| voucher.denomination < amount }.max_by { |voucher| voucher.denomination }
        unless smaller_voucher.nil?
          amount_after_deduction = amount - smaller_voucher.denomination
          transaction.add_used_vouchers(smaller_voucher, smaller_voucher.denomination)
        end
      end
    end
    transaction.actual_money_amount = amount_after_deduction
  end
end
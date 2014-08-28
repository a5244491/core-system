module Merchant::PaymentPlansHelper
  cattr_accessor :plan_type_text_hash, :discount_type_text_hash, :user_type_text_hash, :voucher_status_text_hash
  self.plan_type_text_hash = {
      Pay::PaymentPlan::NONE => '普通刷卡',
      Pay::PaymentPlan::CREDIT_BACK => '优惠返利',
      Pay::PaymentPlan::BANK_DISCOUNT => '刷卡打折',
  }

  self.discount_type_text_hash = {
      Pay::PaymentPlan::RATE => '打折',
      Pay::PaymentPlan::CASH => '抵现',
  }

  self.user_type_text_hash = {
      Pay::PaymentPlan::MEMBERS => '注册会员',
      Pay::PaymentPlan::ALL_USERS => '任意用户'
  }

  self.voucher_status_text_hash = {
      Pay::PaymentPlan::ACCEPT_NONE => '不接受红包',
      Pay::PaymentPlan::ACCEPT_ALL => '接受红包'
  }

  def plan_status_text(plan)
    now = Time.now
    if plan.is_valid?
      '已生效'
    elsif plan.status == Pay::PaymentPlan::INVALID
      '设为失效'
    elsif plan.valid_from > now
      '未到生效时间'
    elsif plan.valid_till < now
      '已经过期'
    end
  end

  def plan_type_text(plan)
    plan_type_text_hash.fetch(plan.plan_type)
  end

  def plan_user_type_text(plan)
    user_type_text_hash.fetch(plan.user_type, '')
  end

  def plan_bank_name(plan)
    plan.bank_name.blank? ? '任意银行' : plan.bank_name
  end

  def plan_money_limit_text(plan)
    plan.minimal_money_amount.to_i == 0 ? '任意金额' : "满#{money_in_yuan(plan.minimal_money_amount)}元"
  end

  def plan_description(plan)
    main = "<b>#{plan_user_type_text(plan)}</b>到店消费<b>#{plan_money_limit_text(plan)}</b>后, 刷<b>#{plan_bank_name(plan)}</b>银行卡可获  </b>"
    if plan.discount_rate.to_f > 0
      main += "消费金额<b>#{plan.discount_rate.to_f * 100}%</b>的直接抵扣, "
    end
    if plan.discount_amount.to_i > 0
      main += "抵扣现金<b>#{money_in_yuan(plan.discount_amount)}</b>元, "
    end
    if plan.customer_rate.to_f > 0
      main += "实际交易金额<b>#{plan.customer_rate.to_f * 100}%</b>的积分, "
    end
    if plan.actual_referer_rate.to_f > 0
      main += "其推荐人可获得其实际交易金额<b>#{plan.actual_referer_rate * 100}%</b>的积分奖励, "
    end
    main += "#{voucher_status_text_hash.fetch(plan.voucher_status)},"
    main += "商户适用扣率:<b>#{plan.merchant_rate.blank? ? '标准扣率' : %Q{#{plan.merchant_rate * 100}%} }</b>"
    main.html_safe
  end

end

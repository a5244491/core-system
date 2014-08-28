module Merchant::PaymentPlansHelper
  cattr_accessor :plan_type_text_hash
  self.plan_type_text_hash = {
      Pay::PaymentPlan::NONE => '普通刷卡',
      Pay::PaymentPlan::CREDIT_BACK => '优惠返利',
      Pay::PaymentPlan::BANK_DISCOUNT => '刷卡打折',
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
end

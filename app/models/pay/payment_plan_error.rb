class Pay::PaymentPlanError < StandardError
  NOT_MEMBER_CARD = '非会员卡无法使用该项功能'
  BANK_CARD_NOT_MATCH = '该银行卡无法使用该项功能'
end
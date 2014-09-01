module Member::VoucherMetaHelper
  def applicable_store_text(voucher_meta)
    applicable_store_name = voucher_meta.try(:applicable_store_name)
    if voucher_meta.applicable_type == Member::VoucherMeta::STORE_GROUP
      "#{applicable_store_name}(群组)"
    else
      applicable_store_name
    end
  end

  def money_condition_text(voucher_meta)
    voucher_meta.money_condition == 0 ? '不限制消费金额' : "消费满#{voucher_meta.money_condition/100.0}元可以使用"
  end

  def voucher_meta_status_text(voucher_meta)
    if voucher_meta.active?
      '生效'
    elsif voucher_meta.disabled?
      '失效'
    elsif voucher_meta.expired?
      '已过有效期'
    end
  end

  def initial_amount_text(voucher_meta)
    if voucher_meta.initial_amount == Member::VoucherMeta::DEFAULT_INITIAL_AMOUNT
      return '不限'
    else
      return voucher_meta.initial_amount
    end
  end

  def limit_per_account_text(voucher_meta)
    if voucher_meta.limit_per_account == Member::VoucherMeta::DEFAULT_LIMIT_PER_ACCOUNT
      return '不限'
    else
      return voucher_meta.limit_per_account
    end
  end

  def hash_voucher_type
    h = {}
    h.store(Member::VoucherMeta::SELF, '平台')
    h.store(Member::VoucherMeta::MERCHANT, '商户')
    h.store(Member::VoucherMeta::BANK, '银行')
    h.store(Member::VoucherMeta::PARTNER, '合作伙伴')
    h
  end

  def voucher_meta_type_text(voucher_type)
    hash_voucher_type[voucher_type]
  end
end

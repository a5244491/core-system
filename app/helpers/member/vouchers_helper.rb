module Member::VouchersHelper
  def credit_applicable_store_text(voucher)
    applicable_store_name = voucher.voucher_meta.try(:applicable_store_name)
    if voucher.applicable_type == Member::VoucherMeta::STORE_GROUP
      "#{applicable_store_name}(群组)"
    else
      applicable_store_name
    end
  end

  def voucher_status_text(voucher)
    voucher.status == Member::Voucher::USED ? '已使用' : '未使用'
  end
end

module Member::VouchersHelper
  def credit_applicable_store_text(voucher)
    applicable_store_text(voucher.voucher_meta)
  end

  def voucher_status_text(voucher)
    voucher.status == Member::Voucher::USED ? '已使用' : '未使用'
  end
end

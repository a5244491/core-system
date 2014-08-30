module Trade::VoucherTransactionLogsHelper
  cattr_accessor :voucher_transaction_type_hash, :voucher_issue_event_hash, :voucher_type_hash
  self.voucher_transaction_type_hash = {
      Trade::VoucherTransactionLog::ISSUE => '红包领取',
      Trade::VoucherTransactionLog::USE => '红包使用'
  }

  self.voucher_issue_event_hash = {
      Trade::VoucherTransactionLog::SYSTEM => '系统赠送',
      Trade::VoucherTransactionLog::CONSUMPTION => '消费后领取'
  }

  self.voucher_type_hash = {
      Member::VoucherMeta::SELF => '平台',
      Member::VoucherMeta::MERCHANT => '商户',
      Member::VoucherMeta::BANK => '银行',
      Member::VoucherMeta::PARTNER => '合作伙伴'
  }
end

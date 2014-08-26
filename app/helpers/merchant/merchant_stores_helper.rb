module Merchant::MerchantStoresHelper
  cattr_accessor :store_status_text_hash
  self.store_status_text_hash = {
      'entering' => '录入中',
      'auditing' => '审核中',
      'audit_passed' => '审核通过',
      'active' => '生效',
      'editing' => '录入中'
  }

  def store_status_text(store)
    store_status_text_hash.fetch(store.status)
  end
end

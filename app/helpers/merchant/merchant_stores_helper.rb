module Merchant::MerchantStoresHelper

  def store_status_text(store)
    case store.status
      when 'entering'
        '录入中'
      when 'auditing'
        '审核中'
      when 'audit_passed'
        '审核通过'
      when 'active'
        '生效'
      else
        '录入中'
    end
  end
end

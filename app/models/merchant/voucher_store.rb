module Merchant
  class VoucherStore < ActiveRecord::Base
    belongs_to :merchant_store
    belongs_to :voucher_meta
  end
end
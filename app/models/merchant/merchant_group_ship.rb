module Merchant
  class MerchantGroupShip < ActiveRecord::Base
     belongs_to :merchant_store
     belongs_to :merchant_group
  end
end
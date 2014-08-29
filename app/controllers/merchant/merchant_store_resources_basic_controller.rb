class Merchant::MerchantStoreResourcesBasicController < ApplicationController
  before_action :set_merchant_store

  protected
  def set_merchant_store
    @merchant_store = Merchant::MerchantStore.find(params[:merchant_store_id])
  end
end
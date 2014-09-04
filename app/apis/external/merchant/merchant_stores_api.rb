#encoding:utf-8
module External::Merchant
  class MerchantStoresAPI < Grape::API
    get '/merchant_stores', rabl: '/merchant_stores/index' do
      @merchant_stores = CoreLib::MerchantStore
      @merchant_stores = @merchant_stores.where(merchant_number: params[:merchant_number]) unless params[:merchant_number].blank?
      unless params[:external_id].blank?
        credit_account = CoreLib::CreditAccount.where(external_id: params[:external_id]).first
        if credit_account.nil?
          @merchant_stores = CoreLib::MerchantStore.none
        else
          @merchant_stores = @merchant_stores.where(credit_account_id: credit_account.id)
        end
      end
      @total = @merchant_stores.size
    end
  end
end
